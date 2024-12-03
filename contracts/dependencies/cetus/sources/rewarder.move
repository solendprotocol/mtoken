module cetus_clmm::rewarder {
    use std::type_name::{TypeName};
    use sui::event;
    use sui::balance::{Balance};
    use sui::transfer::{share_object};
    
    public struct RewarderManager has store {
        rewarders: vector<Rewarder>,
        points_released: u128,
        points_growth_global: u128,
        last_updated_time: u64,
    }
    
    public struct Rewarder has copy, drop, store {
        reward_coin: TypeName,
        emissions_per_second: u128,
        growth_global: u128,
    }
    
    public struct RewarderGlobalVault has store, key {
        id: UID,
        balances: sui::bag::Bag,
    }
    
    public struct RewarderInitEvent has copy, drop {
        global_vault_id: ID,
    }
    
    public struct DepositEvent has copy, drop, store {
        reward_type: TypeName,
        deposit_amount: u64,
        after_amount: u64,
    }
    
    public struct EmergentWithdrawEvent has copy, drop, store {
        reward_type: TypeName,
        withdraw_amount: u64,
        after_amount: u64,
    }
    
    public(package) fun new() : RewarderManager {
        RewarderManager{
            rewarders            : std::vector::empty<Rewarder>(), 
            points_released      : 0, 
            points_growth_global : 0, 
            last_updated_time    : 0,
        }
    }
    
    public(package) fun add_rewarder<T0>(arg0: &mut RewarderManager) {
        let v0 = rewarder_index<T0>(arg0);
        assert!(std::option::is_none<u64>(&v0), 2);
        let v1 = &mut arg0.rewarders;
        assert!(std::vector::length<Rewarder>(v1) <= 3 - 1, 1);
        let v2 = Rewarder{
            reward_coin          : std::type_name::get<T0>(), 
            emissions_per_second : 0, 
            growth_global        : 0,
        };
        std::vector::push_back<Rewarder>(v1, v2);
    }
    
    public fun balance_of<T0>(arg0: &RewarderGlobalVault) : u64 {
        let v0 = std::type_name::get<T0>();
        if (!sui::bag::contains<TypeName>(&arg0.balances, v0)) {
            return 0
        };
        sui::balance::value<T0>(sui::bag::borrow<TypeName, Balance<T0>>(&arg0.balances, v0))
    }
    
    public fun balances(arg0: &RewarderGlobalVault) : &sui::bag::Bag {
        &arg0.balances
    }
    
    public(package) fun borrow_mut_rewarder<T0>(arg0: &mut RewarderManager) : &mut Rewarder {
        let mut v0 = 0;
        while (v0 < std::vector::length<Rewarder>(&arg0.rewarders)) {
            if (std::vector::borrow<Rewarder>(&arg0.rewarders, v0).reward_coin == std::type_name::get<T0>()) {
                return std::vector::borrow_mut<Rewarder>(&mut arg0.rewarders, v0)
            };
            v0 = v0 + 1;
        };
        abort 5
    }
    
    public fun borrow_rewarder<T0>(arg0: &RewarderManager) : &Rewarder {
        let mut v0 = 0;
        while (v0 < std::vector::length<Rewarder>(&arg0.rewarders)) {
            if (std::vector::borrow<Rewarder>(&arg0.rewarders, v0).reward_coin == std::type_name::get<T0>()) {
                return std::vector::borrow<Rewarder>(&arg0.rewarders, v0)
            };
            v0 = v0 + 1;
        };
        abort 5
    }
    
    public fun deposit_reward<T0>(arg0: &cetus_clmm::config::GlobalConfig, arg1: &mut RewarderGlobalVault, arg2: Balance<T0>) : u64 {
        cetus_clmm::config::checked_package_version(arg0);
        let v0 = std::type_name::get<T0>();
        if (!sui::bag::contains<TypeName>(&arg1.balances, v0)) {
            sui::bag::add<TypeName, Balance<T0>>(&mut arg1.balances, v0, sui::balance::zero<T0>());
        };
        let deposit_amount = sui::balance::value<T0>(&arg2);
        let v1 = sui::balance::join<T0>(sui::bag::borrow_mut<TypeName, Balance<T0>>(&mut arg1.balances, std::type_name::get<T0>()), arg2);
        let v2 = DepositEvent{
            reward_type    : std::type_name::get<T0>(), 
            deposit_amount,
            after_amount   : v1,
        };
        event::emit<DepositEvent>(v2);
        v1
    }
    
    public fun emergent_withdraw<T0>(_arg0: &cetus_clmm::config::AdminCap, arg1: &cetus_clmm::config::GlobalConfig, arg2: &mut RewarderGlobalVault, arg3: u64) : Balance<T0> {
        cetus_clmm::config::checked_package_version(arg1);
        let v0 = EmergentWithdrawEvent{
            reward_type     : std::type_name::get<T0>(), 
            withdraw_amount : arg3, 
            after_amount    : balance_of<T0>(arg2),
        };
        event::emit<EmergentWithdrawEvent>(v0);
        withdraw_reward<T0>(arg2, arg3)
    }
    
    public fun emissions_per_second(arg0: &Rewarder) : u128 {
        arg0.emissions_per_second
    }
    
    public fun growth_global(arg0: &Rewarder) : u128 {
        arg0.growth_global
    }
    
    fun init(arg0: &mut TxContext) {
        let v0 = RewarderGlobalVault{
            id       : sui::object::new(arg0), 
            balances : sui::bag::new(arg0),
        };
        let global_vault_id = v0.id.to_inner();
        share_object<RewarderGlobalVault>(v0);
        let v1 = RewarderInitEvent{ global_vault_id };
        event::emit<RewarderInitEvent>(v1);
    }
    
    public fun last_update_time(arg0: &RewarderManager) : u64 {
        arg0.last_updated_time
    }
    
    public fun points_growth_global(arg0: &RewarderManager) : u128 {
        arg0.points_growth_global
    }
    
    public fun points_released(arg0: &RewarderManager) : u128 {
        arg0.points_released
    }
    
    public fun reward_coin(arg0: &Rewarder) : TypeName {
        arg0.reward_coin
    }
    
    public fun rewarder_index<T0>(arg0: &RewarderManager) : std::option::Option<u64> {
        let mut v0 = 0;
        while (v0 < std::vector::length<Rewarder>(&arg0.rewarders)) {
            if (std::vector::borrow<Rewarder>(&arg0.rewarders, v0).reward_coin == std::type_name::get<T0>()) {
                return std::option::some<u64>(v0)
            };
            v0 = v0 + 1;
        };
        std::option::none<u64>()
    }
    
    public fun rewarders(arg0: &RewarderManager) : vector<Rewarder> {
        arg0.rewarders
    }
    
    public fun rewards_growth_global(arg0: &RewarderManager) : vector<u128> {
        let mut v0 = 0;
        let mut v1 = std::vector::empty<u128>();
        while (v0 < std::vector::length<Rewarder>(&arg0.rewarders)) {
            std::vector::push_back<u128>(&mut v1, std::vector::borrow<Rewarder>(&arg0.rewarders, v0).growth_global);
            v0 = v0 + 1;
        };
        v1
    }
    
    public(package) fun settle(reward_manager: &mut RewarderManager, liquidity: u128, current_time: u64) {
        let last_updated_time = reward_manager.last_updated_time;
        reward_manager.last_updated_time = current_time;
        assert!(last_updated_time <= current_time, 3);
        if (liquidity == 0 || current_time == last_updated_time) {
            return
        };
        let time_delta = current_time - last_updated_time;
        let mut i = 0;
        while (i < std::vector::length<Rewarder>(&reward_manager.rewarders)) {
            std::vector::borrow_mut<Rewarder>(&mut reward_manager.rewarders, i).growth_global = std::vector::borrow<Rewarder>(&reward_manager.rewarders, i).growth_global + integer_mate::full_math_u128::mul_div_floor((time_delta as u128), std::vector::borrow<Rewarder>(&reward_manager.rewarders, i).emissions_per_second, liquidity);
            i = i + 1;
        };
        reward_manager.points_released = reward_manager.points_released + (time_delta as u128) * 18446744073709551616000000;
        reward_manager.points_growth_global = reward_manager.points_growth_global + integer_mate::full_math_u128::mul_div_floor((time_delta as u128), 18446744073709551616000000, liquidity);
    }
    
    public(package) fun update_emission<T0>(arg0: &RewarderGlobalVault, arg1: &mut RewarderManager, arg2: u128, arg3: u128, arg4: u64) {
        assert!(arg3 >= 213503982334602, 6);
        settle(arg1, arg2, arg4);
        let v0 = std::type_name::get<T0>();
        assert!(sui::bag::contains<TypeName>(&arg0.balances, v0), 4);
        assert!(sui::balance::value<T0>(sui::bag::borrow<TypeName, Balance<T0>>(&arg0.balances, v0)) >= (integer_mate::full_math_u128::mul_shr(86400, arg3, 64) as u64), 4);
        borrow_mut_rewarder<T0>(arg1).emissions_per_second = arg3;
    }
    
    public(package) fun withdraw_reward<T0>(arg0: &mut RewarderGlobalVault, arg1: u64) : Balance<T0> {
        sui::balance::split<T0>(sui::bag::borrow_mut<TypeName, Balance<T0>>(&mut arg0.balances, std::type_name::get<T0>()), arg1)
    }
    
    // decompiled from Move bytecode v6
}

