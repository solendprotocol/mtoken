#[allow(lint(self_transfer))]
module cetus_clmm::position {
    use std::type_name::{TypeName};
    use sui::tx_context::{sender};
    use move_stl::linked_table::LinkedTable;
    use integer_mate::i32::{I32};

    public struct PositionManager has store {
        tick_spacing: u32,
        position_index: u64,
        positions: LinkedTable<ID, PositionInfo>,
    }
    
    public struct POSITION has drop {}
    
    public struct Position has store, key {
        id: UID,
        pool: ID,
        index: u64,
        coin_type_a: TypeName,
        coin_type_b: TypeName,
        name: std::string::String,
        description: std::string::String,
        url: std::string::String,
        tick_lower_index: I32,
        tick_upper_index: I32,
        liquidity: u128,
    }
    
    public struct PositionInfo has copy, drop, store {
        position_id: ID,
        liquidity: u128,
        tick_lower_index: I32,
        tick_upper_index: I32,
        fee_growth_inside_a: u128,
        fee_growth_inside_b: u128,
        fee_owned_a: u64,
        fee_owned_b: u64,
        points_owned: u128,
        points_growth_inside: u128,
        rewards: vector<PositionReward>,
    }
    
    public struct PositionReward has copy, drop, store {
        growth_inside: u128,
        amount_owned: u64,
    }
    
    public fun is_empty(arg0: &PositionInfo) : bool {
        let mut v0 = true;
        let mut v1 = 0;
        while (v1 < std::vector::length<PositionReward>(&arg0.rewards)) {
            let v2 = if (v0) {
                let v3 = std::vector::borrow<PositionReward>(&arg0.rewards, v1).amount_owned;
                v3 == 0
            } else {
                false
            };
            v0 = v2;
            v1 = v1 + 1;
        };
        let v4 = arg0.liquidity == 0 && arg0.fee_owned_a == 0 && arg0.fee_owned_b == 0;
        v4 && v0
    }
    
    public(package) fun new(arg0: u32, arg1: &mut TxContext) : PositionManager {
        PositionManager{
            tick_spacing   : arg0, 
            position_index : 0, 
            positions      : move_stl::linked_table::new<ID, PositionInfo>(arg1),
        }
    }
    
    fun borrow_mut_position_info(arg0: &mut PositionManager, arg1: ID) : &mut PositionInfo {
        assert!(move_stl::linked_table::contains<ID, PositionInfo>(&arg0.positions, arg1), 6);
        let v0 = move_stl::linked_table::borrow_mut<ID, PositionInfo>(&mut arg0.positions, arg1);
        assert!(v0.position_id == arg1, 6);
        v0
    }
    
    public fun borrow_position_info(arg0: &PositionManager, arg1: ID) : &PositionInfo {
        assert!(move_stl::linked_table::contains<ID, PositionInfo>(&arg0.positions, arg1), 6);
        let v0 = move_stl::linked_table::borrow<ID, PositionInfo>(&arg0.positions, arg1);
        assert!(v0.position_id == arg1, 6);
        v0
    }
    
    public fun check_position_tick_range(tick_lower: I32, tick_upper: I32, tick_spacing: u32) {
        assert!(
            integer_mate::i32::lt(tick_lower, tick_upper)
            && integer_mate::i32::gte(tick_lower, cetus_clmm::tick_math::min_tick())
            && integer_mate::i32::lte(tick_upper, cetus_clmm::tick_math::max_tick())
            && integer_mate::i32::mod(tick_lower, integer_mate::i32::from(tick_spacing)) == integer_mate::i32::zero()
            && integer_mate::i32::mod(tick_upper, integer_mate::i32::from(tick_spacing)) == integer_mate::i32::zero(),
        5);
    }
    
    public(package) fun close_position(arg0: &mut PositionManager, arg1: Position) {
        let v0 = arg1.id.to_inner();
        if (!is_empty(borrow_mut_position_info(arg0, v0))) {
            abort 7
        };
        move_stl::linked_table::remove<ID, PositionInfo>(&mut arg0.positions, v0);
        destroy(arg1);
    }
    
    public(package) fun decrease_liquidity(arg0: &mut PositionManager, arg1: &mut Position, arg2: u128, arg3: u128, arg4: u128, arg5: u128, arg6: vector<u128>) : u128 {
        let v0 = borrow_mut_position_info(arg0, arg1.id.to_inner());
        if (arg2 == 0) {
            return v0.liquidity
        };
        update_fee_internal(v0, arg3, arg4);
        update_points_internal(v0, arg5);
        update_rewards_internal(v0, arg6);
        assert!(v0.liquidity >= arg2, 9);
        v0.liquidity = v0.liquidity - arg2;
        arg1.liquidity = v0.liquidity;
        v0.liquidity
    }
    
    public fun description(arg0: &Position) : std::string::String {
        arg0.description
    }
    
    fun destroy(arg0: Position) {
        let Position {
            id               : v0,
            pool             : _,
            index            : _,
            coin_type_a      : _,
            coin_type_b      : _,
            name             : _,
            description      : _,
            url              : _,
            tick_lower_index : _,
            tick_upper_index : _,
            liquidity        : _,
        } = arg0;
        sui::object::delete(v0);
    }
    
    public fun fetch_positions(arg0: &PositionManager, arg1: vector<ID>, arg2: u64) : vector<PositionInfo> {
        let mut v0 = std::vector::empty<PositionInfo>();
        let v1 = if (std::vector::is_empty<ID>(&arg1)) {
            move_stl::linked_table::head<ID, PositionInfo>(&arg0.positions)
        } else {
            move_stl::linked_table::next<ID, PositionInfo>(move_stl::linked_table::borrow_node<ID, PositionInfo>(&arg0.positions, *std::vector::borrow<ID>(&arg1, 0)))
        };
        let mut v2 = v1;
        let mut v3 = 0;
        while (std::option::is_some<ID>(&v2)) {
            let v4 = move_stl::linked_table::borrow_node<ID, PositionInfo>(&arg0.positions, *std::option::borrow<ID>(&v2));
            v2 = move_stl::linked_table::next<ID, PositionInfo>(v4);
            std::vector::push_back<PositionInfo>(&mut v0, *move_stl::linked_table::borrow_value<ID, PositionInfo>(v4));
            let v5 = v3 + 1;
            v3 = v5;
            if (v5 == arg2) {
                break
            };
        };
        v0
    }
    
    public(package) fun increase_liquidity(arg0: &mut PositionManager, arg1: &mut Position, arg2: u128, arg3: u128, arg4: u128, arg5: u128, arg6: vector<u128>) : u128 {
        let v0 = borrow_mut_position_info(arg0, arg1.id.to_inner());
        update_fee_internal(v0, arg3, arg4);
        update_points_internal(v0, arg5);
        update_rewards_internal(v0, arg6);
        assert!(integer_mate::math_u128::add_check(v0.liquidity, arg2), 8);
        v0.liquidity = v0.liquidity + arg2;
        arg1.liquidity = v0.liquidity;
        v0.liquidity
    }
    
    public fun index(arg0: &Position) : u64 {
        arg0.index
    }
    
    public fun info_fee_growth_inside(arg0: &PositionInfo) : (u128, u128) {
        (arg0.fee_growth_inside_a, arg0.fee_growth_inside_b)
    }
    
    public fun info_fee_owned(arg0: &PositionInfo) : (u64, u64) {
        (arg0.fee_owned_a, arg0.fee_owned_b)
    }
    
    public fun info_liquidity(arg0: &PositionInfo) : u128 {
        arg0.liquidity
    }
    
    public fun info_points_growth_inside(arg0: &PositionInfo) : u128 {
        arg0.points_growth_inside
    }
    
    public fun info_points_owned(arg0: &PositionInfo) : u128 {
        arg0.points_owned
    }
    
    public fun info_position_id(arg0: &PositionInfo) : ID {
        arg0.position_id
    }
    
    public fun info_rewards(arg0: &PositionInfo) : &vector<PositionReward> {
        &arg0.rewards
    }
    
    public fun info_tick_range(arg0: &PositionInfo) : (I32, I32) {
        (arg0.tick_lower_index, arg0.tick_upper_index)
    }
    
    fun init(arg0: POSITION, arg1: &mut TxContext) {
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
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{name}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{coin_type_a}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{coin_type_b}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"https://app.cetus.zone/position?chain=sui&id={id}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{url}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{description}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"https://cetus.zone"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"Cetus"));
        let v4 = sui::package::claim<POSITION>(arg0, arg1);
        let mut v5 = sui::display::new_with_fields<Position>(&v4, v0, v2, arg1);
        sui::display::update_version<Position>(&mut v5);
        sui::transfer::public_transfer<sui::package::Publisher>(v4, sender(arg1));
        sui::transfer::public_transfer<sui::display::Display<Position>>(v5, sender(arg1));
    }
    
    public fun inited_rewards_count(arg0: &PositionManager, arg1: ID) : u64 {
        std::vector::length<PositionReward>(&move_stl::linked_table::borrow<ID, PositionInfo>(&arg0.positions, arg1).rewards)
    }
    
    public fun is_position_exist(arg0: &PositionManager, arg1: ID) : bool {
        move_stl::linked_table::contains<ID, PositionInfo>(&arg0.positions, arg1)
    }
    
    public fun liquidity(arg0: &Position) : u128 {
        arg0.liquidity
    }
    
    public fun name(arg0: &Position) : std::string::String {
        arg0.name
    }
    
    fun new_position_name(arg0: u64, arg1: u64) : std::string::String {
        let mut v0 = std::string::utf8(b"Cetus LP | Pool");
        std::string::append(&mut v0, cetus_clmm::utils::str(arg0));
        std::string::append_utf8(&mut v0, b"-");
        std::string::append(&mut v0, cetus_clmm::utils::str(arg1));
        v0
    }
    
    public(package) fun open_position<T0, T1>(arg0: &mut PositionManager, arg1: ID, arg2: u64, arg3: std::string::String, arg4: I32, arg5: I32, arg6: &mut TxContext) : Position {
        check_position_tick_range(arg4, arg5, arg0.tick_spacing);
        let v0 = arg0.position_index + 1;
        let v1 = Position{
            id               : sui::object::new(arg6), 
            pool             : arg1, 
            index            : v0, 
            coin_type_a      : std::type_name::get<T0>(), 
            coin_type_b      : std::type_name::get<T1>(), 
            name             : new_position_name(arg2, v0), 
            description      : std::string::utf8(b"Cetus Liquidity Position"), 
            url              : arg3, 
            tick_lower_index : arg4, 
            tick_upper_index : arg5, 
            liquidity        : 0,
        };
        let v2 = v1.id.to_inner();
        let v3 = PositionInfo{
            position_id          : v2, 
            liquidity            : 0, 
            tick_lower_index     : arg4, 
            tick_upper_index     : arg5, 
            fee_growth_inside_a  : 0, 
            fee_growth_inside_b  : 0, 
            fee_owned_a          : 0, 
            fee_owned_b          : 0, 
            points_owned         : 0, 
            points_growth_inside : 0, 
            rewards              : std::vector::empty<PositionReward>(),
        };
        move_stl::linked_table::push_back<ID, PositionInfo>(&mut arg0.positions, v2, v3);
        arg0.position_index = v0;
        v1
    }
    
    public fun pool_id(arg0: &Position) : ID {
        arg0.pool
    }
    
    public(package) fun reset_fee(arg0: &mut PositionManager, arg1: ID) : (u64, u64) {
        let v0 = borrow_mut_position_info(arg0, arg1);
        v0.fee_owned_a = 0;
        v0.fee_owned_b = 0;
        (v0.fee_owned_a, v0.fee_owned_b)
    }
    
    public(package) fun reset_rewarder(arg0: &mut PositionManager, arg1: ID, arg2: u64) : u64 {
        let v0 = std::vector::borrow_mut<PositionReward>(&mut borrow_mut_position_info(arg0, arg1).rewards, arg2);
        v0.amount_owned = 0;
        v0.amount_owned
    }
    
    public fun reward_amount_owned(arg0: &PositionReward) : u64 {
        arg0.amount_owned
    }
    
    public fun reward_growth_inside(arg0: &PositionReward) : u128 {
        arg0.growth_inside
    }
    
    public(package) fun rewards_amount_owned(arg0: &PositionManager, arg1: ID) : vector<u64> {
        let v0 = info_rewards(borrow_position_info(arg0, arg1));
        let mut v1 = 0;
        let mut v2 = std::vector::empty<u64>();
        while (v1 < std::vector::length<PositionReward>(v0)) {
            std::vector::push_back<u64>(&mut v2, reward_amount_owned(std::vector::borrow<PositionReward>(v0, v1)));
            v1 = v1 + 1;
        };
        v2
    }
    
    public fun set_display(arg0: &cetus_clmm::config::GlobalConfig, arg1: &sui::package::Publisher, arg2: std::string::String, arg3: std::string::String, arg4: std::string::String, arg5: std::string::String, arg6: &mut TxContext) {
        cetus_clmm::config::checked_package_version(arg0);
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
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{name}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{coin_type_a}"));
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{coin_type_b}"));
        std::vector::push_back<std::string::String>(v3, arg3);
        std::vector::push_back<std::string::String>(v3, std::string::utf8(b"{url}"));
        std::vector::push_back<std::string::String>(v3, arg2);
        std::vector::push_back<std::string::String>(v3, arg4);
        std::vector::push_back<std::string::String>(v3, arg5);
        let mut v4 = sui::display::new_with_fields<Position>(arg1, v0, v2, arg6);
        sui::display::update_version<Position>(&mut v4);
        sui::transfer::public_transfer<sui::display::Display<Position>>(v4, sender(arg6));
    }
    
    public fun tick_range(arg0: &Position) : (I32, I32) {
        (arg0.tick_lower_index, arg0.tick_upper_index)
    }
    
    public(package) fun update_and_reset_fee(arg0: &mut PositionManager, arg1: ID, arg2: u128, arg3: u128) : (u64, u64) {
        let v0 = borrow_mut_position_info(arg0, arg1);
        update_fee_internal(v0, arg2, arg3);
        v0.fee_owned_a = 0;
        v0.fee_owned_b = 0;
        (v0.fee_owned_a, v0.fee_owned_b)
    }
    
    public(package) fun update_and_reset_rewards(arg0: &mut PositionManager, arg1: ID, arg2: vector<u128>, arg3: u64) : u64 {
        assert!(std::vector::length<u128>(&arg2) > arg3, 10);
        let v0 = borrow_mut_position_info(arg0, arg1);
        update_rewards_internal(v0, arg2);
        let v1 = std::vector::borrow_mut<PositionReward>(&mut v0.rewards, arg3);
        v1.amount_owned = 0;
        v1.amount_owned
    }
    
    public(package) fun update_fee(arg0: &mut PositionManager, arg1: ID, arg2: u128, arg3: u128) : (u64, u64) {
        let v0 = borrow_mut_position_info(arg0, arg1);
        update_fee_internal(v0, arg2, arg3);
        info_fee_owned(v0)
    }
    
    fun update_fee_internal(arg0: &mut PositionInfo, arg1: u128, arg2: u128) {
        let v0 = (integer_mate::full_math_u128::mul_shr(arg0.liquidity, integer_mate::math_u128::wrapping_sub(arg1, arg0.fee_growth_inside_a), 64) as u64);
        let v1 = (integer_mate::full_math_u128::mul_shr(arg0.liquidity, integer_mate::math_u128::wrapping_sub(arg2, arg0.fee_growth_inside_b), 64) as u64);
        assert!(integer_mate::math_u64::add_check(arg0.fee_owned_a, v0), 1);
        assert!(integer_mate::math_u64::add_check(arg0.fee_owned_b, v1), 1);
        arg0.fee_owned_a = arg0.fee_owned_a + v0;
        arg0.fee_owned_b = arg0.fee_owned_b + v1;
        arg0.fee_growth_inside_a = arg1;
        arg0.fee_growth_inside_b = arg2;
    }
    
    public(package) fun update_points(arg0: &mut PositionManager, arg1: ID, arg2: u128) : u128 {
        let v0 = borrow_mut_position_info(arg0, arg1);
        update_points_internal(v0, arg2);
        v0.points_owned
    }
    
    fun update_points_internal(arg0: &mut PositionInfo, arg1: u128) {
        let v0 = integer_mate::full_math_u128::mul_shr(arg0.liquidity, integer_mate::math_u128::wrapping_sub(arg1, arg0.points_growth_inside), 64);
        assert!(integer_mate::math_u128::add_check(arg0.points_owned, v0), 3);
        arg0.points_owned = arg0.points_owned + v0;
        arg0.points_growth_inside = arg1;
    }
    
    public(package) fun update_rewards(arg0: &mut PositionManager, arg1: ID, arg2: vector<u128>) : vector<u64> {
        let v0 = borrow_mut_position_info(arg0, arg1);
        update_rewards_internal(v0, arg2);
        let v1 = info_rewards(v0);
        let mut v2 = 0;
        let mut v3 = std::vector::empty<u64>();
        while (v2 < std::vector::length<PositionReward>(v1)) {
            std::vector::push_back<u64>(&mut v3, reward_amount_owned(std::vector::borrow<PositionReward>(v1, v2)));
            v2 = v2 + 1;
        };
        v3
    }
    
    fun update_rewards_internal(arg0: &mut PositionInfo, arg1: vector<u128>) {
        let v0 = std::vector::length<u128>(&arg1);
        if (v0 > 0) {
            let mut v1 = 0;
            while (v1 < v0) {
                let v2 = *std::vector::borrow<u128>(&arg1, v1);
                if (std::vector::length<PositionReward>(&arg0.rewards) > v1) {
                    let v3 = std::vector::borrow_mut<PositionReward>(&mut arg0.rewards, v1);
                    let v4 = (integer_mate::full_math_u128::mul_shr(integer_mate::math_u128::wrapping_sub(v2, v3.growth_inside), arg0.liquidity, 64) as u64);
                    assert!(integer_mate::math_u64::add_check(v3.amount_owned, v4), 2);
                    v3.growth_inside = v2;
                    v3.amount_owned = v3.amount_owned + v4;
                } else {
                    let v5 = PositionReward{
                        growth_inside : v2, 
                        amount_owned  : (integer_mate::full_math_u128::mul_shr(v2, arg0.liquidity, 64) as u64),
                    };
                    std::vector::push_back<PositionReward>(&mut arg0.rewards, v5);
                };
                v1 = v1 + 1;
            };
        };
    }
    
    public fun url(arg0: &Position) : std::string::String {
        arg0.url
    }
    
    // decompiled from Move bytecode v6
}

