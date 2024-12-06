module cetus_clmm::tick {
    use integer_mate::i32::{I32};
    
    public struct TickManager has store {
        tick_spacing: u32,
        ticks: move_stl::skip_list::SkipList<Tick>,
    }
    
    public struct Tick has copy, drop, store {
        index: I32,
        sqrt_price: u128,
        liquidity_net: integer_mate::i128::I128,
        liquidity_gross: u128,
        fee_growth_outside_a: u128,
        fee_growth_outside_b: u128,
        points_growth_outside: u128,
        rewards_growth_outside: vector<u128>,
    }
    
    public(package) fun new(arg0: u32, arg1: u64, arg2: &mut TxContext) : TickManager {
        let mut v0 = TickManager{
            tick_spacing : arg0, 
            ticks        : move_stl::skip_list::new<Tick>(16, 2, arg1, arg2),
        };
        let v1 = cetus_clmm::tick_math::tick_bound();
        let v2 = integer_mate::i32::from(v1 - v1 % arg0);
        let v3 = integer_mate::i32::neg_from(v1 - v1 % arg0);
        move_stl::skip_list::insert<Tick>(&mut v0.ticks, tick_score(v3), default(v3));
        move_stl::skip_list::insert<Tick>(&mut v0.ticks, tick_score(v2), default(v2));
        v0
    }
    
    public fun borrow_tick(arg0: &TickManager, arg1: I32) : &Tick {
        move_stl::skip_list::borrow<Tick>(&arg0.ticks, tick_score(arg1))
    }
    
    public fun borrow_tick_for_swap(arg0: &TickManager, arg1: u64, arg2: bool) : (&Tick, move_stl::option_u64::OptionU64) {
        let v0 = move_stl::skip_list::borrow_node<Tick>(&arg0.ticks, arg1);
        let v1 = if (arg2) {
            move_stl::skip_list::prev_score<Tick>(v0)
        } else {
            move_stl::skip_list::next_score<Tick>(v0)
        };
        (move_stl::skip_list::borrow_value<Tick>(v0), v1)
    }
    
    public(package) fun cross_by_swap(tick_manager: &mut TickManager, arg1: I32, a2b: bool, liquidity: u128, fee_growth_global_a: u128, fee_growth_global_b: u128, points_growth_global: u128, rewards_growth_global: vector<u128>) : u128 {
        let v0 = move_stl::skip_list::borrow_mut<Tick>(&mut tick_manager.ticks, tick_score(arg1));
        let v1 = if (a2b) {
            integer_mate::i128::neg(v0.liquidity_net)
        } else {
            v0.liquidity_net
        };
        let v2 = if (!integer_mate::i128::is_neg(v1)) {
            let v3 = integer_mate::i128::abs_u128(v1);
            assert!(integer_mate::math_u128::add_check(v3, liquidity), 1);
            liquidity + v3
        } else {
            let v4 = integer_mate::i128::abs_u128(v1);
            assert!(liquidity >= v4, 1);
            liquidity - v4
        };
        v0.fee_growth_outside_a = integer_mate::math_u128::wrapping_sub(fee_growth_global_a, v0.fee_growth_outside_a);
        v0.fee_growth_outside_b = integer_mate::math_u128::wrapping_sub(fee_growth_global_b, v0.fee_growth_outside_b);
        let v5 = std::vector::length<u128>(&rewards_growth_global);
        if (v5 > 0) {
            let mut v6 = 0;
            while (v6 < v5) {
                let v7 = *std::vector::borrow<u128>(&rewards_growth_global, v6);
                if (std::vector::length<u128>(&v0.rewards_growth_outside) > v6) {
                    let v8 = integer_mate::math_u128::wrapping_sub(v7, *std::vector::borrow<u128>(&v0.rewards_growth_outside, v6));
                    let v9 = std::vector::borrow_mut<u128>(&mut v0.rewards_growth_outside, v6);
                    *v9 = v8;
                } else {
                    std::vector::push_back<u128>(&mut v0.rewards_growth_outside, v7);
                };
                v6 = v6 + 1;
            };
        };
        v0.points_growth_outside = integer_mate::math_u128::wrapping_sub(points_growth_global, v0.points_growth_outside);
        v2
    }
    
    public(package) fun quote_cross_by_swap(tick_manager: &TickManager, arg1: I32, a2b: bool, liquidity: u128, _fee_growth_global_a: u128, _fee_growth_global_b: u128, _points_growth_global: u128, _rewards_growth_global: vector<u128>) : u128 {
        let v0 = move_stl::skip_list::borrow<Tick>(&tick_manager.ticks, tick_score(arg1));
        let v1 = if (a2b) {
            integer_mate::i128::neg(v0.liquidity_net)
        } else {
            v0.liquidity_net
        };
        let v2 = if (!integer_mate::i128::is_neg(v1)) {
            let v3 = integer_mate::i128::abs_u128(v1);
            assert!(integer_mate::math_u128::add_check(v3, liquidity), 1);
            liquidity + v3
        } else {
            let v4 = integer_mate::i128::abs_u128(v1);
            assert!(liquidity >= v4, 1);
            liquidity - v4
        };
        v2
    }
    
    public(package) fun decrease_liquidity(arg0: &mut TickManager, arg1: I32, arg2: I32, arg3: I32, arg4: u128, arg5: u128, arg6: u128, arg7: u128, arg8: vector<u128>) {
        if (arg4 == 0) {
            return
        };
        let v0 = tick_score(arg2);
        let v1 = tick_score(arg3);
        assert!(move_stl::skip_list::contains<Tick>(&arg0.ticks, v0), 3);
        assert!(move_stl::skip_list::contains<Tick>(&arg0.ticks, v1), 3);
        let v2 = cetus_clmm::tick_math::tick_bound();
        if (update_by_liquidity(move_stl::skip_list::borrow_mut<Tick>(&mut arg0.ticks, v0), arg1, arg4, false, false, false, arg5, arg6, arg7, arg8) == 0 && !integer_mate::i32::eq(arg2, integer_mate::i32::neg_from(v2 - v2 % arg0.tick_spacing))) {
            move_stl::skip_list::remove<Tick>(&mut arg0.ticks, v0);
        };
        if (update_by_liquidity(move_stl::skip_list::borrow_mut<Tick>(&mut arg0.ticks, v1), arg1, arg4, false, false, true, arg5, arg6, arg7, arg8) == 0 && !integer_mate::i32::eq(arg3, integer_mate::i32::from(v2 - v2 % arg0.tick_spacing))) {
            move_stl::skip_list::remove<Tick>(&mut arg0.ticks, v1);
        };
    }
    
    fun default(arg0: I32) : Tick {
        Tick{
            index                  : arg0, 
            sqrt_price             : cetus_clmm::tick_math::get_sqrt_price_at_tick(arg0), 
            liquidity_net          : integer_mate::i128::from(0), 
            liquidity_gross        : 0, 
            fee_growth_outside_a   : 0, 
            fee_growth_outside_b   : 0, 
            points_growth_outside  : 0, 
            rewards_growth_outside : std::vector::empty<u128>(),
        }
    }
    
    fun default_rewards_growth_outside(arg0: u64) : vector<u128> {
        if (arg0 <= 0) {
            std::vector::empty<u128>()
        } else {
            let mut v1 = std::vector::empty<u128>();
            let mut v2 = 0;
            while (v2 < arg0) {
                std::vector::push_back<u128>(&mut v1, 0);
                v2 = v2 + 1;
            };
            v1
        }
    }
    
    public fun fee_growth_outside(arg0: &Tick) : (u128, u128) {
        (arg0.fee_growth_outside_a, arg0.fee_growth_outside_b)
    }
    
    public fun fetch_ticks(arg0: &TickManager, arg1: vector<u32>, arg2: u64) : vector<Tick> {
        let mut v0 = std::vector::empty<Tick>();
        let v1 = if (std::vector::is_empty<u32>(&arg1)) {
            move_stl::skip_list::head<Tick>(&arg0.ticks)
        } else {
            move_stl::skip_list::find_next<Tick>(&arg0.ticks, tick_score(integer_mate::i32::from_u32(*std::vector::borrow<u32>(&arg1, 0))), false)
        };
        let mut v2 = v1;
        let mut v3 = 0;
        while (move_stl::option_u64::is_some(&v2)) {
            let v4 = move_stl::skip_list::borrow_node<Tick>(&arg0.ticks, move_stl::option_u64::borrow(&v2));
            std::vector::push_back<Tick>(&mut v0, *move_stl::skip_list::borrow_value<Tick>(v4));
            v2 = move_stl::skip_list::next_score<Tick>(v4);
            let v5 = v3 + 1;
            v3 = v5;
            if (v5 == arg2) {
                break
            };
        };
        v0
    }
    
    public fun first_score_for_swap(arg0: &TickManager, arg1: I32, arg2: bool) : move_stl::option_u64::OptionU64 {
        if (arg2) {
            move_stl::skip_list::find_prev<Tick>(&arg0.ticks, tick_score(arg1), true)
        } else {
            move_stl::skip_list::find_next<Tick>(&arg0.ticks, tick_score(arg1), false)
        }
    }
    
    public fun get_fee_in_range(arg0: I32, arg1: u128, arg2: u128, arg3: std::option::Option<Tick>, arg4: std::option::Option<Tick>) : (u128, u128) {
        let (v0, v1) = if (std::option::is_none<Tick>(&arg3)) {
            (arg1, arg2)
        } else {
            let v2 = std::option::borrow<Tick>(&arg3);
            let (v3, v4) = if (integer_mate::i32::lt(arg0, v2.index)) {
                (integer_mate::math_u128::wrapping_sub(arg1, v2.fee_growth_outside_a), integer_mate::math_u128::wrapping_sub(arg2, v2.fee_growth_outside_b))
            } else {
                (v2.fee_growth_outside_a, v2.fee_growth_outside_b)
            };
            (v3, v4)
        };
        let (v5, v6) = if (std::option::is_none<Tick>(&arg4)) {
            (0, 0)
        } else {
            let v7 = std::option::borrow<Tick>(&arg4);
            let (v8, v9) = if (integer_mate::i32::lt(arg0, v7.index)) {
                (v7.fee_growth_outside_a, v7.fee_growth_outside_b)
            } else {
                (integer_mate::math_u128::wrapping_sub(arg1, v7.fee_growth_outside_a), integer_mate::math_u128::wrapping_sub(arg2, v7.fee_growth_outside_b))
            };
            (v8, v9)
        };
        (integer_mate::math_u128::wrapping_sub(integer_mate::math_u128::wrapping_sub(arg1, v0), v5), integer_mate::math_u128::wrapping_sub(integer_mate::math_u128::wrapping_sub(arg2, v1), v6))
    }
    
    public fun get_points_in_range(arg0: I32, arg1: u128, arg2: std::option::Option<Tick>, arg3: std::option::Option<Tick>) : u128 {
        let v0 = if (std::option::is_none<Tick>(&arg2)) {
            arg1
        } else {
            let v1 = std::option::borrow<Tick>(&arg2);
            let v2 = if (integer_mate::i32::lt(arg0, v1.index)) {
                integer_mate::math_u128::wrapping_sub(arg1, v1.points_growth_outside)
            } else {
                v1.points_growth_outside
            };
            v2
        };
        let v3 = if (std::option::is_none<Tick>(&arg3)) {
            0
        } else {
            let v4 = std::option::borrow<Tick>(&arg3);
            let v5 = if (integer_mate::i32::lt(arg0, v4.index)) {
                v4.points_growth_outside
            } else {
                integer_mate::math_u128::wrapping_sub(arg1, v4.points_growth_outside)
            };
            v5
        };
        integer_mate::math_u128::wrapping_sub(integer_mate::math_u128::wrapping_sub(arg1, v0), v3)
    }
    
    public fun get_reward_growth_outside(arg0: &Tick, arg1: u64) : u128 {
        if (std::vector::length<u128>(&arg0.rewards_growth_outside) <= arg1) {
            0
        } else {
            *std::vector::borrow<u128>(&arg0.rewards_growth_outside, arg1)
        }
    }
    
    public fun get_rewards_in_range(arg0: I32, arg1: vector<u128>, arg2: std::option::Option<Tick>, arg3: std::option::Option<Tick>) : vector<u128> {
        let mut v0 = std::vector::empty<u128>();
        let mut v1 = 0;
        while (v1 < std::vector::length<u128>(&arg1)) {
            let v2 = *std::vector::borrow<u128>(&arg1, v1);
            let v3 = if (std::option::is_none<Tick>(&arg2)) {
                v2
            } else {
                let v4 = std::option::borrow<Tick>(&arg2);
                let v5 = if (integer_mate::i32::lt(arg0, v4.index)) {
                    integer_mate::math_u128::wrapping_sub(v2, get_reward_growth_outside(v4, v1))
                } else {
                    get_reward_growth_outside(v4, v1)
                };
                v5
            };
            let v6 = if (std::option::is_none<Tick>(&arg3)) {
                0
            } else {
                let v7 = std::option::borrow<Tick>(&arg3);
                let v8 = if (integer_mate::i32::lt(arg0, v7.index)) {
                    get_reward_growth_outside(v7, v1)
                } else {
                    let v9 = get_reward_growth_outside(v7, v1);
                    integer_mate::math_u128::wrapping_sub(v2, v9)
                };
                v8
            };
            std::vector::push_back<u128>(&mut v0, integer_mate::math_u128::wrapping_sub(integer_mate::math_u128::wrapping_sub(v2, v3), v6));
            v1 = v1 + 1;
        };
        v0
    }
    
    public(package) fun increase_liquidity(arg0: &mut TickManager, arg1: I32, arg2: I32, arg3: I32, arg4: u128, arg5: u128, arg6: u128, arg7: u128, arg8: vector<u128>) {
        if (arg4 == 0) {
            return
        };
        let v0 = tick_score(arg2);
        let v1 = tick_score(arg3);
        let mut v2 = false;
        let mut v3 = false;
        if (!move_stl::skip_list::contains<Tick>(&arg0.ticks, v0)) {
            move_stl::skip_list::insert<Tick>(&mut arg0.ticks, v0, default(arg2));
            v3 = true;
        };
        if (!move_stl::skip_list::contains<Tick>(&arg0.ticks, v1)) {
            move_stl::skip_list::insert<Tick>(&mut arg0.ticks, v1, default(arg3));
            v2 = true;
        };
        update_by_liquidity(move_stl::skip_list::borrow_mut<Tick>(&mut arg0.ticks, v0), arg1, arg4, v3, true, false, arg5, arg6, arg7, arg8);
        update_by_liquidity(move_stl::skip_list::borrow_mut<Tick>(&mut arg0.ticks, v1), arg1, arg4, v2, true, true, arg5, arg6, arg7, arg8);
    }
    
    public fun index(arg0: &Tick) : I32 {
        arg0.index
    }
    
    public fun liquidity_gross(arg0: &Tick) : u128 {
        arg0.liquidity_gross
    }
    
    public fun liquidity_net(arg0: &Tick) : integer_mate::i128::I128 {
        arg0.liquidity_net
    }
    
    public fun points_growth_outside(arg0: &Tick) : u128 {
        arg0.points_growth_outside
    }
    
    public fun rewards_growth_outside(arg0: &Tick) : &vector<u128> {
        &arg0.rewards_growth_outside
    }
    
    public fun sqrt_price(arg0: &Tick) : u128 {
        arg0.sqrt_price
    }
    
    fun tick_score(arg0: I32) : u64 {
        let v0 = integer_mate::i32::as_u32(integer_mate::i32::add(arg0, integer_mate::i32::from(cetus_clmm::tick_math::tick_bound())));
        assert!(v0 >= 0 && v0 <= cetus_clmm::tick_math::tick_bound() * 2, 2);
        (v0 as u64)
    }
    
    public fun tick_spacing(arg0: &TickManager) : u32 {
        arg0.tick_spacing
    }
    
    public(package) fun try_borrow_tick(arg0: &TickManager, arg1: I32) : std::option::Option<Tick> {
        let v0 = tick_score(arg1);
        if (!move_stl::skip_list::contains<Tick>(&arg0.ticks, v0)) {
            return std::option::none<Tick>()
        };
        std::option::some<Tick>(*move_stl::skip_list::borrow<Tick>(&arg0.ticks, v0))
    }
    
    fun update_by_liquidity(arg0: &mut Tick, arg1: I32, arg2: u128, arg3: bool, arg4: bool, arg5: bool, arg6: u128, arg7: u128, arg8: u128, arg9: vector<u128>) : u128 {
        let v0 = if (arg4) {
            assert!(integer_mate::math_u128::add_check(arg0.liquidity_gross, arg2), 0);
            arg0.liquidity_gross + arg2
        } else {
            assert!(arg0.liquidity_gross >= arg2, 1);
            arg0.liquidity_gross - arg2
        };
        let (v1, v2, v3, v4) = if (arg3) {
            let (v5, v6, v7, v8) = if (integer_mate::i32::lt(arg1, arg0.index)) {
                (0, 0, default_rewards_growth_outside(std::vector::length<u128>(&arg9)), 0)
            } else {
                (arg6, arg7, arg9, arg8)
            };
            (v5, v6, v7, v8)
        } else {
            (arg0.fee_growth_outside_a, arg0.fee_growth_outside_b, arg0.rewards_growth_outside, arg0.points_growth_outside)
        };
        let (v9, v10) = if (arg4) {
            let (v11, v12) = if (arg5) {
                let (v13, v14) = integer_mate::i128::overflowing_sub(arg0.liquidity_net, integer_mate::i128::from(arg2));
                (v13, v14)
            } else {
                let (v15, v16) = integer_mate::i128::overflowing_add(arg0.liquidity_net, integer_mate::i128::from(arg2));
                (v15, v16)
            };
            (v11, v12)
        } else {
            let (v17, v18) = if (arg5) {
                let (v19, v20) = integer_mate::i128::overflowing_add(arg0.liquidity_net, integer_mate::i128::from(arg2));
                (v19, v20)
            } else {
                let (v21, v22) = integer_mate::i128::overflowing_sub(arg0.liquidity_net, integer_mate::i128::from(arg2));
                (v21, v22)
            };
            (v17, v18)
        };
        if (v10) {
            abort 0
        };
        arg0.liquidity_gross = v0;
        arg0.liquidity_net = v9;
        arg0.fee_growth_outside_a = v1;
        arg0.fee_growth_outside_b = v2;
        arg0.rewards_growth_outside = v3;
        arg0.points_growth_outside = v4;
        v0
    }
    
    // decompiled from Move bytecode v6
}

