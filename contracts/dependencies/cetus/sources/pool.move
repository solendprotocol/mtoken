#[allow(lint(self_transfer))]
module cetus_clmm::pool {
    use std::type_name::{Self, TypeName};
    use sui::event;
    use sui::balance::{Self, Balance};
    use sui::clock::{Clock};
    use sui::tx_context::{sender};
    use cetus_clmm::tick::{Self, TickManager};
    use cetus_clmm::rewarder::{Self, RewarderManager, RewarderGlobalVault};
    use cetus_clmm::position::{Self, PositionManager, Position, PositionInfo};
    use integer_mate::i32::{I32};
    use cetus_clmm::tick_math;
    use cetus_clmm::clmm_math;
    use cetus_clmm::config;
    use cetus_clmm::partner::{Self, Partner};

    public struct POOL has drop {}
    
    public struct Pool<phantom A, phantom B> has store, key {
        id: UID,
        coin_a: Balance<A>,
        coin_b: Balance<B>,
        tick_spacing: u32,
        fee_rate: u64,
        liquidity: u128,
        current_sqrt_price: u128,
        current_tick_index: I32,
        fee_growth_global_a: u128,
        fee_growth_global_b: u128,
        fee_protocol_coin_a: u64,
        fee_protocol_coin_b: u64,
        tick_manager: TickManager,
        rewarder_manager: RewarderManager,
        position_manager: PositionManager,
        is_pause: bool,
        index: u64,
        url: std::string::String,
    }
    
    public struct SwapResult has copy, drop {
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        ref_fee_amount: u64,
        steps: u64,
    }
    
    public struct FlashSwapReceipt<phantom T0, phantom T1> {
        pool_id: ID,
        a2b: bool,
        partner_id: ID,
        pay_amount: u64,
        ref_fee_amount: u64,
    }
    
    public struct AddLiquidityReceipt<phantom T0, phantom T1> {
        pool_id: ID,
        amount_a: u64,
        amount_b: u64,
    }
    
    public struct CalculatedSwapResult has copy, drop, store {
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        fee_rate: u64,
        after_sqrt_price: u128,
        is_exceed: bool,
        step_results: vector<SwapStepResult>,
    }
    
    public struct SwapStepResult has copy, drop, store {
        current_sqrt_price: u128,
        target_sqrt_price: u128,
        current_liquidity: u128,
        amount_in: u64,
        amount_out: u64,
        fee_amount: u64,
        remainder_amount: u64,
    }
    
    public struct OpenPositionEvent has copy, drop, store {
        pool: ID,
        tick_lower: I32,
        tick_upper: I32,
        position: ID,
    }
    
    public struct ClosePositionEvent has copy, drop, store {
        pool: ID,
        position: ID,
    }
    
    public struct AddLiquidityEvent has copy, drop, store {
        pool: ID,
        position: ID,
        tick_lower: I32,
        tick_upper: I32,
        liquidity: u128,
        after_liquidity: u128,
        amount_a: u64,
        amount_b: u64,
    }
    
    public struct RemoveLiquidityEvent has copy, drop, store {
        pool: ID,
        position: ID,
        tick_lower: I32,
        tick_upper: I32,
        liquidity: u128,
        after_liquidity: u128,
        amount_a: u64,
        amount_b: u64,
    }
    
    public struct SwapEvent has copy, drop, store {
        atob: bool,
        pool: ID,
        partner: ID,
        amount_in: u64,
        amount_out: u64,
        ref_amount: u64,
        fee_amount: u64,
        vault_a_amount: u64,
        vault_b_amount: u64,
        before_sqrt_price: u128,
        after_sqrt_price: u128,
        steps: u64,
    }
    
    public struct CollectProtocolFeeEvent has copy, drop, store {
        pool: ID,
        amount_a: u64,
        amount_b: u64,
    }
    
    public struct CollectFeeEvent has copy, drop, store {
        position: ID,
        pool: ID,
        amount_a: u64,
        amount_b: u64,
    }
    
    public struct UpdateFeeRateEvent has copy, drop, store {
        pool: ID,
        old_fee_rate: u64,
        new_fee_rate: u64,
    }
    
    public struct UpdateEmissionEvent has copy, drop, store {
        pool: ID,
        rewarder_type: TypeName,
        emissions_per_second: u128,
    }
    
    public struct AddRewarderEvent has copy, drop, store {
        pool: ID,
        rewarder_type: TypeName,
    }
    
    public struct CollectRewardEvent has copy, drop, store {
        position: ID,
        pool: ID,
        amount: u64,
    }
    
    public(package) fun new<A, B>(tick_spacing: u32, current_sqrt_price: u128, fee_rate: u64, url: std::string::String, index: u64, clock: &Clock, ctx: &mut TxContext) : Pool<A, B> {
        Pool<A, B> {
            id: object::new(ctx),
            coin_a: balance::zero<A>(),
            coin_b: balance::zero<B>(),
            tick_spacing: tick_spacing,
            fee_rate,
            liquidity: 0,
            current_sqrt_price,
            current_tick_index: tick_math::get_tick_at_sqrt_price(current_sqrt_price),
            fee_growth_global_a: 0,
            fee_growth_global_b: 0,
            fee_protocol_coin_a: 0,
            fee_protocol_coin_b: 0,
            tick_manager: tick::new(tick_spacing, sui::clock::timestamp_ms(clock), ctx),
            rewarder_manager: rewarder::new(),
            position_manager: position::new(tick_spacing, ctx),
            is_pause: false,
            index,
            url,
        }
    }

    
    public fun get_amount_by_liquidity(arg0: I32, arg1: I32, arg2: I32, arg3: u128, arg4: u128, arg5: bool) : (u64, u64) {
        if (arg4 == 0) {
            return (0, 0)
        };
        if (integer_mate::i32::lt(arg2, arg0)) {
            (clmm_math::get_delta_a(tick_math::get_sqrt_price_at_tick(arg0), tick_math::get_sqrt_price_at_tick(arg1), arg4, arg5), 0)
        } else {
            let (v2, v3) = if (integer_mate::i32::lt(arg2, arg1)) {
                (clmm_math::get_delta_a(arg3, tick_math::get_sqrt_price_at_tick(arg1), arg4, arg5), clmm_math::get_delta_b(tick_math::get_sqrt_price_at_tick(arg0), arg3, arg4, arg5))
            } else {
                (0, clmm_math::get_delta_b(tick_math::get_sqrt_price_at_tick(arg0), tick_math::get_sqrt_price_at_tick(arg1), arg4, arg5))
            };
            (v2, v3)
        }
    }
    
    public fun borrow_position_info<A, B>(arg0: &Pool<A, B>, arg1: ID) : &PositionInfo {
        position::borrow_position_info(&arg0.position_manager, arg1)
    }
    
    public fun close_position<A, B>(config: &config::GlobalConfig, pool: &mut Pool<A, B>, position: Position) {
        config::checked_package_version(config);
        assert!(!pool.is_pause, 13);
        let position_id = object::id(&position);

        position::close_position(&mut pool.position_manager, position);

        event::emit(ClosePositionEvent{
            pool: pool.id.to_inner(),
            position: position_id,
        });
    }
    
    public fun fetch_positions<A, B>(arg0: &Pool<A, B>, arg1: vector<ID>, arg2: u64) : vector<PositionInfo> {
        position::fetch_positions(&arg0.position_manager, arg1, arg2)
    }
    
    public fun is_position_exist<A, B>(arg0: &Pool<A, B>, arg1: ID) : bool {
        position::is_position_exist(&arg0.position_manager, arg1)
    }
    
    public fun liquidity<A, B>(pool: &Pool<A, B>) : u128 {
        pool.liquidity
    }
    
    public fun open_position<A, B>(config: &config::GlobalConfig, pool: &mut Pool<A, B>, tick_lower: u32, tick_upper: u32, ctx: &mut TxContext) : Position {
        config::checked_package_version(config);
        assert!(!pool.is_pause, 13);
        let tick_lower = integer_mate::i32::from_u32(tick_lower);
        let tick_upper = integer_mate::i32::from_u32(tick_upper);
        let pool_id = pool.id.to_inner();

        let position = position::open_position<A, B>(
            &mut pool.position_manager,
            pool_id,
            pool.index,
            pool.url,
            tick_lower,
            tick_upper,
            ctx
        );

        event::emit(OpenPositionEvent{
            pool       : pool_id, 
            tick_lower : tick_lower, 
            tick_upper : tick_upper, 
            position   : object::id(&position),
        });
        position
    }
    
    public fun update_emission<A, B, RewardType>(config: &config::GlobalConfig, pool: &mut Pool<A, B>, reward_vault: &RewarderGlobalVault, emissions_per_second: u128, clock: &Clock, ctx: &TxContext) {
        config::checked_package_version(config);
        assert!(!pool.is_pause, 13);
        config::check_pool_manager_role(config, sender(ctx));
        rewarder::update_emission<RewardType>(reward_vault, &mut pool.rewarder_manager, pool.liquidity, emissions_per_second, sui::clock::timestamp_ms(clock) / 1000);

        event::emit(UpdateEmissionEvent{
            pool                 : pool.id.to_inner(),
            rewarder_type        : type_name::get<RewardType>(), 
            emissions_per_second : emissions_per_second,
        });
    }
    
    public fun borrow_tick<A, B>(pool: &Pool<A, B>, arg1: I32) : &tick::Tick {
        tick::borrow_tick(&pool.tick_manager, arg1)
    }
    
    public fun fetch_ticks<A, B>(pool: &Pool<A, B>, arg1: vector<u32>, arg2: u64) : vector<tick::Tick> {
        tick::fetch_ticks(&pool.tick_manager, arg1, arg2)
    }
    
    public fun index<A, B>(pool: &Pool<A, B>) : u64 {
        pool.index
    }
    
    public fun add_liquidity<A, B>(config: &config::GlobalConfig, pool: &mut Pool<A, B>, position: &mut Position, liquidity: u128, clock: &Clock) : AddLiquidityReceipt<A, B> {
        config::checked_package_version(config);
        assert!(liquidity != 0, 3);
        add_liquidity_internal<A, B>(pool, position, false, liquidity, 0, false, sui::clock::timestamp_ms(clock) / 1000)
    }
    
    public fun add_liquidity_fix_coin<A, B>(config: &config::GlobalConfig, pool: &mut Pool<A, B>, position: &mut Position, amount: u64, from_a: bool, clock: &Clock) : AddLiquidityReceipt<A, B> {
        config::checked_package_version(config);
        assert!(amount > 0, 0);
        add_liquidity_internal<A, B>(pool, position, true, 0, amount, from_a, sui::clock::timestamp_ms(clock) / 1000)
    }
    
    fun add_liquidity_internal<A, B>(pool: &mut Pool<A, B>, position: &mut Position, get_liquidity_by_amount: bool, liquidity: u128, amount: u64, from_a: bool, current_time: u64) : AddLiquidityReceipt<A, B> {
        assert!(!pool.is_pause, 13);
        rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, current_time);
        let (tick_lower, tick_upper) = position::tick_range(position);

        let (liquidity_delta, amount_a, amount_b) = if (get_liquidity_by_amount) {
            let (liquidity_delta, amount_a, amount_b) = clmm_math::get_liquidity_by_amount(tick_lower, tick_upper, pool.current_tick_index, pool.current_sqrt_price, amount, from_a);
            (liquidity_delta, amount_a, amount_b)
        } else {
            let (amount_a, amount_b) = clmm_math::get_amount_by_liquidity(tick_lower, tick_upper, pool.current_tick_index, pool.current_sqrt_price, liquidity, true);
            (liquidity, amount_a, amount_b)
        };

        let (fee_a, fee_b, rewards, points) = get_fee_rewards_points_in_tick_range<A, B>(pool, tick_lower, tick_upper);
        tick::increase_liquidity(&mut pool.tick_manager, pool.current_tick_index, tick_lower, tick_upper, liquidity_delta, pool.fee_growth_global_a, pool.fee_growth_global_b, rewarder::points_growth_global(&pool.rewarder_manager), rewarder::rewards_growth_global(&pool.rewarder_manager));

        if (integer_mate::i32::gte(pool.current_tick_index, tick_lower) && integer_mate::i32::lt(pool.current_tick_index, tick_upper)) {
            assert!(integer_mate::math_u128::add_check(pool.liquidity, liquidity_delta), 1);
            pool.liquidity = pool.liquidity + liquidity_delta;
        };

        event::emit(AddLiquidityEvent {
            pool: pool.id.to_inner(), 
            position: object::id(position), 
            tick_lower: tick_lower, 
            tick_upper: tick_upper, 
            liquidity: liquidity, 
            after_liquidity: position::increase_liquidity(&mut pool.position_manager, position, liquidity_delta, fee_a, fee_b, points, rewards), 
            amount_a: amount_a, 
            amount_b: amount_b,
        });

        AddLiquidityReceipt<A, B>{
            pool_id: pool.id.to_inner(), 
            amount_a: amount_a, 
            amount_b: amount_b,
        }
    }

    public fun add_liquidity_pay_amount<A, B>(receipt: &AddLiquidityReceipt<A, B>) : (u64, u64) {
        (receipt.amount_a, receipt.amount_b)
    }
    
    public fun balances<A, B>(pool: &Pool<A, B>) : (&Balance<A>, &Balance<B>) {
        (&pool.coin_a, &pool.coin_b)
    }
    
    public fun calculate_and_update_fee<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: ID) : (u64, u64) {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        let v0 = position::borrow_position_info(&arg1.position_manager, arg2);
        if (position::info_liquidity(v0) != 0) {
            let (v3, v4) = position::info_tick_range(v0);
            let (v5, v6) = get_fee_in_tick_range<A, B>(arg1, v3, v4);
            let (v7, v8) = position::update_fee(&mut arg1.position_manager, arg2, v5, v6);
            (v7, v8)
        } else {
            let (v9, v10) = position::info_fee_owned(position::borrow_position_info(&arg1.position_manager, arg2));
            (v9, v10)
        }
    }
    
    public fun calculate_and_update_points<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: ID, arg3: &Clock) : u128 {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        rewarder::settle(&mut arg1.rewarder_manager, arg1.liquidity, sui::clock::timestamp_ms(arg3) / 1000);
        let v0 = position::borrow_position_info(&arg1.position_manager, arg2);
        if (position::info_liquidity(v0) != 0) {
            let (v2, v3) = position::info_tick_range(v0);
            let points = get_points_in_tick_range<A, B>(arg1, v2, v3);
            position::update_points(&mut arg1.position_manager, arg2, points)
        } else {
            position::info_points_owned(position::borrow_position_info(&arg1.position_manager, arg2))
        }
    }
    
    public fun calculate_and_update_reward<A, B, RewardType>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: ID, arg3: &Clock) : u64 {
        let mut v0 = rewarder::rewarder_index<RewardType>(&arg1.rewarder_manager);
        assert!(std::option::is_some<u64>(&v0), 17);
        let v1 = calculate_and_update_rewards<A, B>(arg0, arg1, arg2, arg3);
        *std::vector::borrow<u64>(&v1, std::option::extract<u64>(&mut v0))
    }
    
    public fun calculate_and_update_rewards<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: ID, arg3: &Clock) : vector<u64> {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        rewarder::settle(&mut arg1.rewarder_manager, arg1.liquidity, sui::clock::timestamp_ms(arg3) / 1000);
        let v0 = position::borrow_position_info(&arg1.position_manager, arg2);
        if (position::info_liquidity(v0) != 0) {
            let (v2, v3) = position::info_tick_range(v0);
            let rewards = get_rewards_in_tick_range<A, B>(arg1, v2, v3);
            position::update_rewards(&mut arg1.position_manager, arg2, rewards)
        } else {
            position::rewards_amount_owned(&arg1.position_manager, arg2)
        }
    }
    
    public fun calculate_swap_result<A, B>(arg0: &Pool<A, B>, arg1: bool, arg2: bool, arg3: u64) : CalculatedSwapResult {
        let mut v0 = arg0.current_sqrt_price;
        let mut v1 = arg0.liquidity;
        let mut v2 = default_swap_result();
        let mut v3 = arg3;
        let mut v4 = tick::first_score_for_swap(&arg0.tick_manager, arg0.current_tick_index, arg1);
        let mut v5 = CalculatedSwapResult{
            amount_in        : 0, 
            amount_out       : 0, 
            fee_amount       : 0, 
            fee_rate         : arg0.fee_rate, 
            after_sqrt_price : arg0.current_sqrt_price, 
            is_exceed        : false, 
            step_results     : std::vector::empty<SwapStepResult>(),
        };
        while (v3 > 0) {
            if (move_stl::option_u64::is_none(&v4)) {
                v5.is_exceed = true;
                break
            };
            let (v6, v7) = tick::borrow_tick_for_swap(&arg0.tick_manager, move_stl::option_u64::borrow(&v4), arg1);
            v4 = v7;
            let v8 = tick::sqrt_price(v6);
            let (v9, v10, v11, v12) = clmm_math::compute_swap_step(v0, v8, v1, v3, arg0.fee_rate, arg1, arg2);
            if (v9 != 0 || v12 != 0) {
                if (arg2) {
                    let v13 = check_remainer_amount_sub(v3, v9);
                    v3 = check_remainer_amount_sub(v13, v12);
                } else {
                    v3 = check_remainer_amount_sub(v3, v10);
                };
                update_swap_result(&mut v2, v9, v10, v12);
            };
            let v14 = SwapStepResult{
                current_sqrt_price : v0, 
                target_sqrt_price  : v8, 
                current_liquidity  : v1, 
                amount_in          : v9, 
                amount_out         : v10, 
                fee_amount         : v12, 
                remainder_amount   : v3,
            };
            std::vector::push_back<SwapStepResult>(&mut v5.step_results, v14);
            if (v11 == v8) {
                v0 = v8;
                let v15 = if (arg1) {
                    integer_mate::i128::neg(tick::liquidity_net(v6))
                } else {
                    tick::liquidity_net(v6)
                };
                if (!integer_mate::i128::is_neg(v15)) {
                    let v16 = integer_mate::i128::abs_u128(v15);
                    assert!(integer_mate::math_u128::add_check(v1, v16), 1);
                    v1 = v1 + v16;
                    continue
                };
                let v17 = integer_mate::i128::abs_u128(v15);
                assert!(v1 >= v17, 1);
                v1 = v1 - v17;
                continue
            };
            v0 = v11;
        };
        v5.amount_in = v2.amount_in;
        v5.amount_out = v2.amount_out;
        v5.fee_amount = v2.fee_amount;
        v5.after_sqrt_price = v0;
        v5
    }
    
    public fun calculate_swap_result_step_results(arg0: &CalculatedSwapResult) : &vector<SwapStepResult> {
        &arg0.step_results
    }
    
    public fun calculated_swap_result_after_sqrt_price(arg0: &CalculatedSwapResult) : u128 {
        arg0.after_sqrt_price
    }
    
    public fun calculated_swap_result_amount_in(arg0: &CalculatedSwapResult) : u64 {
        arg0.amount_in
    }
    
    public fun calculated_swap_result_amount_out(arg0: &CalculatedSwapResult) : u64 {
        arg0.amount_out
    }
    
    public fun calculated_swap_result_fee_amount(arg0: &CalculatedSwapResult) : u64 {
        arg0.fee_amount
    }
    
    public fun calculated_swap_result_is_exceed(arg0: &CalculatedSwapResult) : bool {
        arg0.is_exceed
    }
    
    public fun calculated_swap_result_step_swap_result(arg0: &CalculatedSwapResult, arg1: u64) : &SwapStepResult {
        std::vector::borrow<SwapStepResult>(&arg0.step_results, arg1)
    }
    
    public fun calculated_swap_result_steps_length(arg0: &CalculatedSwapResult) : u64 {
        std::vector::length<SwapStepResult>(&arg0.step_results)
    }
    
    fun check_remainer_amount_sub(arg0: u64, arg1: u64) : u64 {
        assert!(arg0 >= arg1, 5);
        arg0 - arg1
    }
    
    public fun collect_fee<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &Position, arg3: bool) : (Balance<A>, Balance<B>) {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        let v0 = object::id(arg2);
        let (v1, v2) = position::tick_range(arg2);
        let (v3, v4) = if (arg3 && position::liquidity(arg2) != 0) {
            let (v5, v6) = get_fee_in_tick_range<A, B>(arg1, v1, v2);
            let (v7, v8) = position::update_and_reset_fee(&mut arg1.position_manager, v0, v5, v6);
            (v7, v8)
        } else {
            let (v9, v10) = position::reset_fee(&mut arg1.position_manager, v0);
            (v9, v10)
        };
        let v11 = CollectFeeEvent{
            position : v0, 
            pool     : arg1.id.to_inner(), 
            amount_a : v3, 
            amount_b : v4,
        };
        event::emit<CollectFeeEvent>(v11);
        (balance::split<A>(&mut arg1.coin_a, v3), balance::split<B>(&mut arg1.coin_b, v4))
    }
    
    public fun collect_protocol_fee<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &TxContext) : (Balance<A>, Balance<B>) {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        config::check_protocol_fee_claim_role(arg0, sender(arg2));
        let v0 = arg1.fee_protocol_coin_a;
        let v1 = arg1.fee_protocol_coin_b;
        arg1.fee_protocol_coin_a = 0;
        arg1.fee_protocol_coin_b = 0;
        let v2 = CollectProtocolFeeEvent{
            pool     : arg1.id.to_inner(), 
            amount_a : v0, 
            amount_b : v1,
        };
        event::emit<CollectProtocolFeeEvent>(v2);
        (balance::split<A>(&mut arg1.coin_a, v0), balance::split<B>(&mut arg1.coin_b, v1))
    }
    
    public fun collect_reward<A, B, RewardType>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &Position, arg3: &mut RewarderGlobalVault, arg4: bool, arg5: &Clock) : Balance<RewardType> {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        rewarder::settle(&mut arg1.rewarder_manager, arg1.liquidity, sui::clock::timestamp_ms(arg5) / 1000);
        let v0 = object::id(arg2);
        let mut v1 = rewarder::rewarder_index<RewardType>(&arg1.rewarder_manager);
        assert!(std::option::is_some<u64>(&v1), 17);
        let v2 = std::option::extract<u64>(&mut v1);
        let v3 = if (arg4 && position::liquidity(arg2) != 0 || position::inited_rewards_count(&arg1.position_manager, v0) <= v2) {
            let (v4, v5) = position::tick_range(arg2);
            let rewards = get_rewards_in_tick_range<A, B>(arg1, v4, v5);
            position::update_and_reset_rewards(&mut arg1.position_manager, v0, rewards, v2)
        } else {
            position::reset_rewarder(&mut arg1.position_manager, v0, v2)
        };
        let v6 = CollectRewardEvent{
            position : v0, 
            pool     : arg1.id.to_inner(), 
            amount   : v3,
        };
        event::emit<CollectRewardEvent>(v6);
        rewarder::withdraw_reward<RewardType>(arg3, v3)
    }
    
    public fun current_sqrt_price<A, B>(arg0: &Pool<A, B>) : u128 {
        arg0.current_sqrt_price
    }
    
    public fun current_tick_index<A, B>(arg0: &Pool<A, B>) : I32 {
        arg0.current_tick_index
    }
    
    fun default_swap_result() : SwapResult {
        SwapResult{
            amount_in      : 0, 
            amount_out     : 0, 
            fee_amount     : 0, 
            ref_fee_amount : 0, 
            steps          : 0,
        }
    }
    
    public fun fee_rate<A, B>(arg0: &Pool<A, B>) : u64 {
        arg0.fee_rate
    }
    
    public fun fees_growth_global<A, B>(arg0: &Pool<A, B>) : (u128, u128) {
        (arg0.fee_growth_global_a, arg0.fee_growth_global_b)
    }
    
    public fun flash_swap<A, B>(
        config: &config::GlobalConfig,
        pool: &mut Pool<A, B>,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        sqrt_price_limit: u128,
        clock: &Clock
    ) : (Balance<A>, Balance<B>, FlashSwapReceipt<A, B>) {
        config::checked_package_version(config);
        assert!(!pool.is_pause, 13);
        flash_swap_internal<A, B>(
            pool,
            config,
            object::id_from_address(@0x0),
            0,
            a2b,
            by_amount_in,
            amount,
            sqrt_price_limit,
            clock
        )
    }
    
    fun flash_swap_internal<A, B>(
        pool: &mut Pool<A, B>,
        config: &config::GlobalConfig,
        partner: ID,
        ref_fee: u64,
        a2b: bool,
        by_amount_in: bool,
        amount: u64,
        sqrt_price_limit: u128,
        clock: &Clock
    ) : (Balance<A>, Balance<B>, FlashSwapReceipt<A, B>) {
        assert!(!pool.is_pause, 13);
        rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, sui::clock::timestamp_ms(clock) / 1000);

        if (a2b) {
            assert!(pool.current_sqrt_price > sqrt_price_limit && sqrt_price_limit >= tick_math::min_sqrt_price(), 11);
        } else {
            assert!(pool.current_sqrt_price < sqrt_price_limit && sqrt_price_limit <= tick_math::max_sqrt_price(), 11);
        };
        let v0 = swap_in_pool<A, B>(pool, a2b, by_amount_in, sqrt_price_limit, amount, config::protocol_fee_rate(config), ref_fee);
        let (v1, v2) = if (a2b) {
            (balance::zero<A>(), balance::split<B>(&mut pool.coin_b, v0.amount_out))
        } else {
            (balance::split<A>(&mut pool.coin_a, v0.amount_out), balance::zero<B>())
        };
        let v3 = SwapEvent{
            atob              : a2b, 
            pool              : pool.id.to_inner(), 
            partner           : partner, 
            amount_in         : v0.amount_in + v0.fee_amount, 
            amount_out        : v0.amount_out, 
            ref_amount        : v0.ref_fee_amount, 
            fee_amount        : v0.fee_amount, 
            vault_a_amount    : balance::value<A>(&pool.coin_a), 
            vault_b_amount    : balance::value<B>(&pool.coin_b), 
            before_sqrt_price : pool.current_sqrt_price, 
            after_sqrt_price  : pool.current_sqrt_price, 
            steps             : v0.steps,
        };
        event::emit<SwapEvent>(v3);
        let v4 = FlashSwapReceipt<A, B>{
            pool_id        : pool.id.to_inner(), 
            a2b            : a2b, 
            partner_id     : partner, 
            pay_amount     : v0.amount_in + v0.fee_amount, 
            ref_fee_amount : v0.ref_fee_amount,
        };
        (v1, v2, v4)
    }
    
    public fun flash_swap_with_partner<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &Partner, arg3: bool, arg4: bool, arg5: u64, arg6: u128, arg7: &Clock) : (Balance<A>, Balance<B>, FlashSwapReceipt<A, B>) {
        config::checked_package_version(arg0);
        flash_swap_internal<A, B>(arg1, arg0, arg2.partner_id(), partner::current_ref_fee_rate(arg2, sui::clock::timestamp_ms(arg7) / 1000), arg3, arg4, arg5, arg6, arg7)
    }
    
    public fun get_fee_in_tick_range<A, B>(arg0: &Pool<A, B>, arg1: I32, arg2: I32) : (u128, u128) {
        tick::get_fee_in_range(arg0.current_tick_index, arg0.fee_growth_global_a, arg0.fee_growth_global_b, tick::try_borrow_tick(&arg0.tick_manager, arg1), tick::try_borrow_tick(&arg0.tick_manager, arg2))
    }
    
    public fun get_fee_rewards_points_in_tick_range<A, B>(arg0: &Pool<A, B>, tick_lower: I32, tick_upper: I32) : (u128, u128, vector<u128>, u128) {
        let lower_tick = tick::try_borrow_tick(&arg0.tick_manager, tick_lower);
        let upper_tick = tick::try_borrow_tick(&arg0.tick_manager, tick_upper);
        let (fee_a, fee_b) = tick::get_fee_in_range(arg0.current_tick_index, arg0.fee_growth_global_a, arg0.fee_growth_global_b, lower_tick, upper_tick);
        (fee_a, fee_b, tick::get_rewards_in_range(arg0.current_tick_index, rewarder::rewards_growth_global(&arg0.rewarder_manager), lower_tick, upper_tick), tick::get_points_in_range(arg0.current_tick_index, rewarder::points_growth_global(&arg0.rewarder_manager), lower_tick, upper_tick))
    }
    
    public fun get_liquidity_from_amount(arg0: I32, arg1: I32, arg2: I32, arg3: u128, arg4: u64, arg5: bool) : (u128, u64, u64) {
        let mut v0 = 0;
        let mut v1 = 0;
        let v2 = if (arg5) {
            v0 = arg4;
            if (integer_mate::i32::lt(arg2, arg0)) {
                clmm_math::get_liquidity_from_a(tick_math::get_sqrt_price_at_tick(arg0), tick_math::get_sqrt_price_at_tick(arg1), arg4, false)
            } else {
                assert!(integer_mate::i32::lt(arg2, arg1), 10);
                let v3 = clmm_math::get_liquidity_from_a(arg3, tick_math::get_sqrt_price_at_tick(arg1), arg4, false);
                v1 = clmm_math::get_delta_b(arg3, tick_math::get_sqrt_price_at_tick(arg0), v3, true);
                v3
            }
        } else {
            v1 = arg4;
            if (integer_mate::i32::gte(arg2, arg1)) {
                clmm_math::get_liquidity_from_b(tick_math::get_sqrt_price_at_tick(arg0), tick_math::get_sqrt_price_at_tick(arg1), arg4, false)
            } else {
                assert!(integer_mate::i32::gte(arg2, arg0), 10);
                let v4 = clmm_math::get_liquidity_from_b(tick_math::get_sqrt_price_at_tick(arg0), arg3, arg4, false);
                v0 = clmm_math::get_delta_a(arg3, tick_math::get_sqrt_price_at_tick(arg1), v4, true);
                v4
            }
        };
        (v2, v0, v1)
    }
    
    public fun get_points_in_tick_range<A, B>(arg0: &Pool<A, B>, arg1: I32, arg2: I32) : u128 {
        tick::get_points_in_range(arg0.current_tick_index, rewarder::points_growth_global(&arg0.rewarder_manager), tick::try_borrow_tick(&arg0.tick_manager, arg1), tick::try_borrow_tick(&arg0.tick_manager, arg2))
    }
    
    public fun get_position_fee<A, B>(arg0: &Pool<A, B>, arg1: ID) : (u64, u64) {
        position::info_fee_owned(position::borrow_position_info(&arg0.position_manager, arg1))
    }
    
    public fun get_position_points<A, B>(arg0: &Pool<A, B>, arg1: ID) : u128 {
        position::info_points_owned(position::borrow_position_info(&arg0.position_manager, arg1))
    }
    
    public fun get_position_reward<A, B, RewardType>(arg0: &Pool<A, B>, arg1: ID) : u64 {
        let mut v0 = rewarder::rewarder_index<RewardType>(&arg0.rewarder_manager);
        assert!(std::option::is_some<u64>(&v0), 17);
        let v1 = position::rewards_amount_owned(&arg0.position_manager, arg1);
        *std::vector::borrow<u64>(&v1, std::option::extract<u64>(&mut v0))
    }
    
    public fun get_position_rewards<A, B>(arg0: &Pool<A, B>, arg1: ID) : vector<u64> {
        position::rewards_amount_owned(&arg0.position_manager, arg1)
    }
    
    public fun get_rewards_in_tick_range<A, B>(arg0: &Pool<A, B>, arg1: I32, arg2: I32) : vector<u128> {
        tick::get_rewards_in_range(arg0.current_tick_index, rewarder::rewards_growth_global(&arg0.rewarder_manager), tick::try_borrow_tick(&arg0.tick_manager, arg1), tick::try_borrow_tick(&arg0.tick_manager, arg2))
    }
    
    fun init(arg0: POOL, arg1: &mut TxContext) {
        sui::transfer::public_transfer<sui::package::Publisher>(sui::package::claim<POOL>(arg0, arg1), sender(arg1));
    }
    
    public fun initialize_rewarder<A, B, RewardType>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &TxContext) {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        config::check_pool_manager_role(arg0, sender(arg2));
        rewarder::add_rewarder<RewardType>(&mut arg1.rewarder_manager);
        let v0 = AddRewarderEvent{
            pool          : arg1.id.to_inner(), 
            rewarder_type : type_name::get<RewardType>(),
        };
        event::emit<AddRewarderEvent>(v0);
    }
    
    public fun is_pause<A, B>(arg0: &Pool<A, B>) : bool {
        arg0.is_pause
    }
    
    public fun pause<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &TxContext) {
        config::checked_package_version(arg0);
        config::check_pool_manager_role(arg0, sender(arg2));
        arg1.is_pause = true;
    }
    
    public fun position_manager<A, B>(arg0: &Pool<A, B>) : &PositionManager {
        &arg0.position_manager
    }
    
    public fun protocol_fee<A, B>(arg0: &Pool<A, B>) : (u64, u64) {
        (arg0.fee_protocol_coin_a, arg0.fee_protocol_coin_b)
    }
    
    public fun pool_id<A, B>(arg0: &Pool<A, B>) : ID {
        arg0.id.to_inner()
    }
    
    public fun ref_fee_amount<A, B>(arg0: &FlashSwapReceipt<A, B>) : u64 {
        arg0.ref_fee_amount
    }
    
    public fun remove_liquidity<A, B>(
        config: &config::GlobalConfig,
        pool: &mut Pool<A, B>,
        position: &mut Position,
        liquidity: u128,
        clock: &Clock
    ) : (Balance<A>, Balance<B>) {
        config::checked_package_version(config);
        assert!(!pool.is_pause, 13);
        assert!(liquidity > 0, 3);
        rewarder::settle(&mut pool.rewarder_manager, pool.liquidity, sui::clock::timestamp_ms(clock) / 1000);
        let (v0, v1) = position::tick_range(position);
        let (v2, v3, v4, v5) = get_fee_rewards_points_in_tick_range<A, B>(pool, v0, v1);
        tick::decrease_liquidity(&mut pool.tick_manager, pool.current_tick_index, v0, v1, liquidity, pool.fee_growth_global_a, pool.fee_growth_global_b, rewarder::points_growth_global(&pool.rewarder_manager), rewarder::rewards_growth_global(&pool.rewarder_manager));
        if (integer_mate::i32::lte(v0, pool.current_tick_index) && integer_mate::i32::lt(pool.current_tick_index, v1)) {
            pool.liquidity = pool.liquidity - liquidity;
        };
        let (v6, v7) = get_amount_by_liquidity(v0, v1, pool.current_tick_index, pool.current_sqrt_price, liquidity, false);
        let v8 = RemoveLiquidityEvent{
            pool            : pool.id.to_inner(), 
            position        : object::id(position), 
            tick_lower      : v0, 
            tick_upper      : v1, 
            liquidity       : liquidity, 
            after_liquidity : position::decrease_liquidity(&mut pool.position_manager, position, liquidity, v2, v3, v5, v4), 
            amount_a        : v6, 
            amount_b        : v7,
        };
        event::emit<RemoveLiquidityEvent>(v8);
        (balance::split<A>(&mut pool.coin_a, v6), balance::split<B>(&mut pool.coin_b, v7))
    }
    
    public fun repay_add_liquidity<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: Balance<A>, arg3: Balance<B>, arg4: AddLiquidityReceipt<A, B>) {
        config::checked_package_version(arg0);
        let AddLiquidityReceipt {
            pool_id  : v0,
            amount_a : v1,
            amount_b : v2,
        } = arg4;
        assert!(balance::value<A>(&arg2) == v1, 0);
        assert!(balance::value<B>(&arg3) == v2, 0);
        assert!(arg1.id.to_inner() == v0, 12);
        balance::join<A>(&mut arg1.coin_a, arg2);
        balance::join<B>(&mut arg1.coin_b, arg3);
    }
    
    public fun repay_flash_swap<A, B>(config: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: Balance<A>, arg3: Balance<B>, arg4: FlashSwapReceipt<A, B>) {
        config::checked_package_version(config);
        assert!(!arg1.is_pause, 13);
        let FlashSwapReceipt {
            pool_id        : v0,
            a2b            : v1,
            partner_id     : _,
            pay_amount     : v3,
            ref_fee_amount : v4,
        } = arg4;
        assert!(arg1.id.to_inner() == v0, 14);
        assert!(v4 == 0, 14);

        if (v1) {
            assert!(balance::value<A>(&arg2) == v3, 0);
            balance::join<A>(&mut arg1.coin_a, arg2);
            balance::destroy_zero<B>(arg3);
        } else {
            assert!(balance::value<B>(&arg3) == v3, 0);
            balance::join<B>(&mut arg1.coin_b, arg3);
            balance::destroy_zero<A>(arg2);
        };
    }
    
    public fun repay_flash_swap_with_partner<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &mut Partner, mut arg3: Balance<A>, mut arg4: Balance<B>, arg5: FlashSwapReceipt<A, B>) {
        config::checked_package_version(arg0);
        let FlashSwapReceipt {
            pool_id        : v0,
            a2b            : v1,
            partner_id     : v2,
            pay_amount     : v3,
            ref_fee_amount : v4,
        } = arg5;
        assert!(arg1.id.to_inner() == v0, 14);
        assert!(arg2.partner_id() == v2, 14);
        if (v1) {
            assert!(balance::value<A>(&arg3) == v3, 0);
            if (v4 > 0) {
                partner::receive_ref_fee<A>(arg2, balance::split<A>(&mut arg3, v4));
            };
            balance::join<A>(&mut arg1.coin_a, arg3);
            balance::destroy_zero<B>(arg4);
        } else {
            assert!(balance::value<B>(&arg4) == v3, 0);
            if (v4 > 0) {
                partner::receive_ref_fee<B>(arg2, balance::split<B>(&mut arg4, v4));
            };
            balance::join<B>(&mut arg1.coin_b, arg4);
            balance::destroy_zero<A>(arg3);
        };
    }
    
    public fun rewarder_manager<A, B>(arg0: &Pool<A, B>) : &RewarderManager {
        &arg0.rewarder_manager
    }
    
    public fun set_display<A, B>(arg0: &config::GlobalConfig, arg1: &sui::package::Publisher, arg2: std::string::String, arg3: std::string::String, arg4: std::string::String, arg5: std::string::String, arg6: std::string::String, arg7: std::string::String, arg8: &mut TxContext) {
        config::checked_package_version(arg0);
        let mut v0 = std::vector::empty<std::string::String>();
        let v1 = &mut v0;
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"name"));
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"coin_a"));
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"coin_b"));
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"link"));
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"image_url"));
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"description"));
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"project_url"));
        std::vector::push_back<std::string::String>(v1, std::string::utf8(b"creator"));
        let mut v2 = std::vector::empty<std::string::String>();
        let v3 = &mut v2;
        std::vector::push_back<std::string::String>(v3, arg2);
        std::vector::push_back<std::string::String>(v3, std::string::from_ascii(type_name::into_string(type_name::get<A>())));
        std::vector::push_back<std::string::String>(v3, std::string::from_ascii(type_name::into_string(type_name::get<B>())));
        std::vector::push_back<std::string::String>(v3, arg5);
        std::vector::push_back<std::string::String>(v3, arg4);
        std::vector::push_back<std::string::String>(v3, arg3);
        std::vector::push_back<std::string::String>(v3, arg6);
        std::vector::push_back<std::string::String>(v3, arg7);
        let mut v4 = sui::display::new_with_fields<Pool<A, B>>(arg1, v0, v2, arg8);
        sui::display::update_version<Pool<A, B>>(&mut v4);
        sui::transfer::public_transfer<sui::display::Display<Pool<A, B>>>(v4, sender(arg8));
    }
    
    public fun step_swap_result_amount_in(arg0: &SwapStepResult) : u64 {
        arg0.amount_in
    }
    
    public fun step_swap_result_amount_out(arg0: &SwapStepResult) : u64 {
        arg0.amount_out
    }
    
    public fun step_swap_result_current_liquidity(arg0: &SwapStepResult) : u128 {
        arg0.current_liquidity
    }
    
    public fun step_swap_result_current_sqrt_price(arg0: &SwapStepResult) : u128 {
        arg0.current_sqrt_price
    }
    
    public fun step_swap_result_fee_amount(arg0: &SwapStepResult) : u64 {
        arg0.fee_amount
    }
    
    public fun step_swap_result_remainder_amount(arg0: &SwapStepResult) : u64 {
        arg0.remainder_amount
    }
    
    public fun step_swap_result_target_sqrt_price(arg0: &SwapStepResult) : u128 {
        arg0.target_sqrt_price
    }
    
    fun swap_in_pool<A, B>(pool: &mut Pool<A, B>, a2b: bool, by_amount_in: bool, sqrt_price_limit: u128, amount: u64, protocol_fee_rate: u64, ref_fee_rate: u64) : SwapResult {
        assert!(ref_fee_rate <= 10000, 16);
        let mut v0 = default_swap_result();
        let mut v1 = amount;
        let mut v2 = tick::first_score_for_swap(&pool.tick_manager, pool.current_tick_index, a2b);
        let mut v3 = 0;

        while (v1 > 0 && pool.current_sqrt_price != sqrt_price_limit) {
            if (move_stl::option_u64::is_none(&v2)) {
                abort 4
            };
            let (v4, v5) = tick::borrow_tick_for_swap(&pool.tick_manager, move_stl::option_u64::borrow(&v2), a2b);
            v2 = v5;
            let v6 = tick::index(v4);
            let v7 = tick::sqrt_price(v4);
            let v8 = if (a2b) {
                integer_mate::math_u128::max(sqrt_price_limit, v7)
            } else {
                integer_mate::math_u128::min(sqrt_price_limit, v7)
            };
            let (v9, v10, v11, v12) = clmm_math::compute_swap_step(pool.current_sqrt_price, v8, pool.liquidity, v1, pool.fee_rate, a2b, by_amount_in);
            if (v9 != 0 || v12 != 0) {
                if (by_amount_in) {
                    let v13 = check_remainer_amount_sub(v1, v9);
                    v1 = check_remainer_amount_sub(v13, v12);
                } else {
                    v1 = check_remainer_amount_sub(v1, v10);
                };
                update_swap_result(&mut v0, v9, v10, v12);
                v3 = v3 + update_pool_fee<A, B>(pool, v12, protocol_fee_rate, a2b);
            };
            if (v11 == v7) {
                pool.current_sqrt_price = v8;
                let v14 = if (a2b) {
                    integer_mate::i32::sub(v6, integer_mate::i32::from(1))
                } else {
                    v6
                };
                pool.current_tick_index = v14;
                pool.liquidity = tick::cross_by_swap(&mut pool.tick_manager, v6, a2b, pool.liquidity, pool.fee_growth_global_a, pool.fee_growth_global_b, rewarder::points_growth_global(&pool.rewarder_manager), rewarder::rewards_growth_global(&pool.rewarder_manager));
                continue
            };
            if (pool.current_sqrt_price != v7) {
                pool.current_sqrt_price = v11;
                pool.current_tick_index = tick_math::get_tick_at_sqrt_price(v11);
                continue
            };
        };
        v0.ref_fee_amount = integer_mate::full_math_u64::mul_div_floor(v3, ref_fee_rate, 10000);
        if (a2b) {
            pool.fee_protocol_coin_a = pool.fee_protocol_coin_a + v3 - v0.ref_fee_amount;
        } else {
            pool.fee_protocol_coin_b = pool.fee_protocol_coin_b + v3 - v0.ref_fee_amount;
        };
        v0
    }

    public(package) fun quote_swap_in_pool<A, B>(pool: &Pool<A, B>, a2b: bool, by_amount_in: bool, sqrt_price_limit: u128, amount: u64, protocol_fee_rate: u64, ref_fee_rate: u64) : (SwapResult, u128) {
        assert!(ref_fee_rate <= 10000, 16);
        let mut swap_result = default_swap_result();
        let mut v1 = amount;
        let mut v2 = tick::first_score_for_swap(&pool.tick_manager, pool.current_tick_index, a2b);
        let mut v3 = 0;

        let mut current_sqrt_price = pool.current_sqrt_price;
        let mut _current_tick_index = pool.current_tick_index;
        let mut liquidity = pool.liquidity;

        while (v1 > 0 && current_sqrt_price != sqrt_price_limit) {
            if (move_stl::option_u64::is_none(&v2)) {
                abort 4
            };
            let (v4, v5) = tick::borrow_tick_for_swap(&pool.tick_manager, move_stl::option_u64::borrow(&v2), a2b);
            v2 = v5;
            let v6 = tick::index(v4);
            let v7 = tick::sqrt_price(v4);
            let v8 = if (a2b) {
                integer_mate::math_u128::max(sqrt_price_limit, v7)
            } else {
                integer_mate::math_u128::min(sqrt_price_limit, v7)
            };
            let (v9, v10, v11, v12) = clmm_math::compute_swap_step(current_sqrt_price, v8, liquidity, v1, pool.fee_rate, a2b, by_amount_in);
            if (v9 != 0 || v12 != 0) {
                if (by_amount_in) {
                    let v13 = check_remainer_amount_sub(v1, v9);
                    v1 = check_remainer_amount_sub(v13, v12);
                } else {
                    v1 = check_remainer_amount_sub(v1, v10);
                };
                update_swap_result(&mut swap_result, v9, v10, v12);
                v3 = v3 + quote_update_pool_fee<A, B>(pool, v12, protocol_fee_rate, a2b);
            };
            if (v11 == v7) {
                current_sqrt_price = v8;
                let v14 = if (a2b) {
                    integer_mate::i32::sub(v6, integer_mate::i32::from(1))
                } else {
                    v6
                };
                _current_tick_index = v14;
                liquidity = tick::quote_cross_by_swap(&pool.tick_manager, v6, a2b, liquidity, pool.fee_growth_global_a, pool.fee_growth_global_b, rewarder::points_growth_global(&pool.rewarder_manager), rewarder::rewards_growth_global(&pool.rewarder_manager));
                continue
            };
            if (current_sqrt_price != v7) {
                current_sqrt_price = v11;
                _current_tick_index = tick_math::get_tick_at_sqrt_price(v11);
                continue
            };
        };
        swap_result.ref_fee_amount = integer_mate::full_math_u64::mul_div_floor(v3, ref_fee_rate, 10000);
    
        (swap_result, current_sqrt_price)
    }
    
    public fun swap_pay_amount<A, B>(arg0: &FlashSwapReceipt<A, B>) : u64 {
        arg0.pay_amount
    }
    
    public fun tick_manager<A, B>(arg0: &Pool<A, B>) : &TickManager {
        &arg0.tick_manager
    }
    
    public fun tick_spacing<A, B>(arg0: &Pool<A, B>) : u32 {
        arg0.tick_spacing
    }
    
    public fun unpause<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: &TxContext) {
        config::checked_package_version(arg0);
        config::check_pool_manager_role(arg0, sender(arg2));
        arg1.is_pause = false;
    }
    
    public fun update_fee_rate<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: u64, arg3: &TxContext) {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        if (arg2 > config::max_fee_rate()) {
            abort 9
        };
        config::check_pool_manager_role(arg0, sender(arg3));
        arg1.fee_rate = arg2;
        let v0 = UpdateFeeRateEvent{
            pool         : arg1.id.to_inner(), 
            old_fee_rate : arg1.fee_rate, 
            new_fee_rate : arg2,
        };
        event::emit<UpdateFeeRateEvent>(v0);
    }
    
    fun update_pool_fee<A, B>(arg0: &mut Pool<A, B>, arg1: u64, arg2: u64, arg3: bool) : u64 {
        let v0 = integer_mate::full_math_u64::mul_div_ceil(arg1, arg2, 10000);
        let v1 = arg1 - v0;
        if (v1 == 0 || arg0.liquidity == 0) {
            return v0
        };
        if (arg3) {
            arg0.fee_growth_global_a = integer_mate::math_u128::wrapping_add(arg0.fee_growth_global_a, ((v1 as u128) << 64) / arg0.liquidity);
        } else {
            arg0.fee_growth_global_b = integer_mate::math_u128::wrapping_add(arg0.fee_growth_global_b, ((v1 as u128) << 64) / arg0.liquidity);
        };
        v0
    }
   
    fun quote_update_pool_fee<A, B>(arg0: &Pool<A, B>, arg1: u64, arg2: u64, _arg3: bool) : u64 {
        let v0 = integer_mate::full_math_u64::mul_div_ceil(arg1, arg2, 10000);
        let v1 = arg1 - v0;
        if (v1 == 0 || arg0.liquidity == 0) {
            return v0
        };

        v0
    }
    
    public fun update_position_url<A, B>(arg0: &config::GlobalConfig, arg1: &mut Pool<A, B>, arg2: std::string::String, arg3: &TxContext) {
        config::checked_package_version(arg0);
        assert!(!arg1.is_pause, 13);
        config::check_pool_manager_role(arg0, sender(arg3));
        arg1.url = arg2;
    }
    
    fun update_swap_result(arg0: &mut SwapResult, arg1: u64, arg2: u64, arg3: u64) {
        assert!(integer_mate::math_u64::add_check(arg0.amount_in, arg1), 6);
        assert!(integer_mate::math_u64::add_check(arg0.amount_out, arg2), 7);
        assert!(integer_mate::math_u64::add_check(arg0.fee_amount, arg3), 8);
        arg0.amount_in = arg0.amount_in + arg1;
        arg0.amount_out = arg0.amount_out + arg2;
        arg0.fee_amount = arg0.fee_amount + arg3;
        arg0.steps = arg0.steps + 1;
    }
    
    public fun url<A, B>(arg0: &Pool<A, B>) : std::string::String {
        arg0.url
    }
    
    // decompiled from Move bytecode v6
}

