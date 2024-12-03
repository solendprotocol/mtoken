#[allow(lint(share_owned))]
module cetus_clmm::factory {
    use std::type_name::{TypeName};
    use sui::event;
    use sui::clock::{Clock};
    use sui::transfer::{share_object};
    use move_stl::linked_table::LinkedTable;

    public struct PoolSimpleInfo has copy, drop, store {
        pool_id: ID,
        pool_key: ID,
        coin_type_a: TypeName,
        coin_type_b: TypeName,
        tick_spacing: u32,
    }
    
    public struct Pools has store, key {
        id: UID,
        list: LinkedTable<ID, PoolSimpleInfo>,
        index: u64,
    }
    
    public struct InitFactoryEvent has copy, drop {
        pools_id: ID,
    }
    
    public struct CreatePoolEvent has copy, drop {
        pool_id: ID,
        coin_type_a: std::string::String,
        coin_type_b: std::string::String,
        tick_spacing: u32,
    }
    
    public fun coin_types(arg0: &PoolSimpleInfo) : (TypeName, TypeName) {
        (arg0.coin_type_a, arg0.coin_type_b)
    }
    
    public fun create_pool<T0, T1>(arg0: &mut Pools, arg1: &cetus_clmm::config::GlobalConfig, arg2: u32, arg3: u128, arg4: std::string::String, arg5: &Clock, arg6: &mut TxContext) {
        cetus_clmm::config::checked_package_version(arg1);
        sui::transfer::public_share_object<cetus_clmm::pool::Pool<T0, T1>>(create_pool_internal<T0, T1>(arg0, arg1, arg2, arg3, arg4, arg5, arg6));
    }
    
    fun create_pool_internal<A, B>(pools: &mut Pools, global_config: &cetus_clmm::config::GlobalConfig, tick_spacing: u32, current_sqrt_price: u128, url: std::string::String, clock: &Clock, ctx: &mut TxContext) : cetus_clmm::pool::Pool<A, B> {
        assert!(current_sqrt_price >= cetus_clmm::tick_math::min_sqrt_price() && current_sqrt_price <= cetus_clmm::tick_math::max_sqrt_price(), 2);
        
        let coin_type_a = std::type_name::get<A>();
        let coin_type_b = std::type_name::get<B>();
        assert!(coin_type_a != coin_type_b, 3);

        let pool_key = new_pool_key<A, B>(tick_spacing);
        if (move_stl::linked_table::contains<ID, PoolSimpleInfo>(&pools.list, pool_key)) {
            abort 1
        };
        let url = if (std::string::length(&url) == 0) {
            std::string::utf8(b"https://bq7bkvdje7gvgmv66hrxdy7wx5h5ggtrrnmt66rdkkehb64rvz3q.arweave.net/DD4VVGknzVMyvvHjceP2coin_type_a_TGnGLWT96I1KIcPuRrnc")
        } else {
            url
        };

        let pool = cetus_clmm::pool::new<A, B>(tick_spacing, current_sqrt_price, cetus_clmm::config::get_fee_rate(tick_spacing, global_config), url, pools.index, clock, ctx);
        pools.index = pools.index + 1;
        let pool_id = pool.pool_id();
        
        let pool_info = PoolSimpleInfo {
            pool_id,
            pool_key,
            coin_type_a,
            coin_type_b,
            tick_spacing,
        };
        move_stl::linked_table::push_back<ID, PoolSimpleInfo>(&mut pools.list, pool_key, pool_info);

        event::emit(
            CreatePoolEvent{
                pool_id,
                coin_type_a: std::string::from_ascii(std::type_name::into_string(coin_type_a)), 
                coin_type_b: std::string::from_ascii(std::type_name::into_string(coin_type_b)), 
                tick_spacing,
            }
        );

        pool
    }
    
    public fun create_pool_with_liquidity<A, B>(
        pools: &mut Pools,
        config: &cetus_clmm::config::GlobalConfig,
        tick_spacing: u32,
        current_sqrt_price: u128,
        url: std::string::String,
        tick_lower: u32,
        tick_upper: u32,
        mut coin_a: sui::coin::Coin<A>,
        mut coin_b: sui::coin::Coin<B>,
        max_amount_a: u64,
        max_amount_b: u64,
        from_a: bool,
        clock: &Clock,
        ctx: &mut TxContext
    ) : (cetus_clmm::position::Position, sui::coin::Coin<A>, sui::coin::Coin<B>) {
        cetus_clmm::config::checked_package_version(config);
        let mut pool = create_pool_internal<A, B>(
            pools,
            config,
            tick_spacing,
            current_sqrt_price,
            url,
            clock,
            ctx
        );

        let mut position = cetus_clmm::pool::open_position<A, B>(config, &mut pool, tick_lower, tick_upper, ctx);
        
        let amount = if (from_a) {
            max_amount_a
        } else {
            max_amount_b
        };
    
        let v3 = cetus_clmm::pool::add_liquidity_fix_coin<A, B>(
            config,
            &mut pool,
            &mut position,
            amount,
            from_a,
            clock
        );
        let (amount_a, amount_b) = cetus_clmm::pool::add_liquidity_pay_amount<A, B>(&v3);
        if (from_a) {
            assert!(amount_b <= max_amount_b, 4);
        } else {
            assert!(amount_a <= max_amount_a, 5);
        };
    
        cetus_clmm::pool::repay_add_liquidity<A, B>(config, &mut pool, sui::coin::into_balance<A>(sui::coin::split<A>(&mut coin_a, amount_a, ctx)), sui::coin::into_balance<B>(sui::coin::split<B>(&mut coin_b, amount_b, ctx)), v3);
        sui::transfer::public_share_object<cetus_clmm::pool::Pool<A, B>>(pool);
        (position, coin_a, coin_b)
    }
    
    public fun fetch_pools(arg0: &Pools, arg1: vector<ID>, arg2: u64) : vector<PoolSimpleInfo> {
        let mut v0 = std::vector::empty<PoolSimpleInfo>();
        let v1 = if (std::vector::is_empty<ID>(&arg1)) {
            move_stl::linked_table::head<ID, PoolSimpleInfo>(&arg0.list)
        } else {
            move_stl::linked_table::next<ID, PoolSimpleInfo>(move_stl::linked_table::borrow_node<ID, PoolSimpleInfo>(&arg0.list, *std::vector::borrow<ID>(&arg1, 0)))
        };
        let mut v2 = v1;
        let mut v3 = 0;
        while (std::option::is_some<ID>(&v2) && v3 < arg2) {
            let v4 = move_stl::linked_table::borrow_node<ID, PoolSimpleInfo>(&arg0.list, *std::option::borrow<ID>(&v2));
            v2 = move_stl::linked_table::next<ID, PoolSimpleInfo>(v4);
            std::vector::push_back<PoolSimpleInfo>(&mut v0, *move_stl::linked_table::borrow_value<ID, PoolSimpleInfo>(v4));
            v3 = v3 + 1;
        };
        v0
    }
    
    public fun index(arg0: &Pools) : u64 {
        arg0.index
    }
    
    fun init(arg0: &mut TxContext) {
        let v0 = Pools {
            id    : sui::object::new(arg0), 
            list  : move_stl::linked_table::new<ID, PoolSimpleInfo>(arg0), 
            index : 0,
        };
        let pools_id = v0.id.to_inner();
        share_object<Pools>(v0);
        let v1 = InitFactoryEvent{ pools_id };
        event::emit<InitFactoryEvent>(v1);
    }
    
    public fun new_pool_key<A, B>(tick_spacing: u32) : ID {
        let type_a = std::type_name::into_string(std::type_name::get<A>());
        let mut type_a_bytes = *std::ascii::as_bytes(&type_a);
        let type_b = std::type_name::into_string(std::type_name::get<B>());
        let type_b_bytes = *std::ascii::as_bytes(&type_b);
        let mut i = 0;
        let mut is_a_larger_than_b = false;
        
        while (i < std::vector::length<u8>(&type_b_bytes)) {
            let current_b_byte = *std::vector::borrow<u8>(&type_b_bytes, i);
            let can_compare_bytes = !is_a_larger_than_b && i < std::vector::length<u8>(&type_a_bytes);
            if (can_compare_bytes) {
                let current_a_byte = *std::vector::borrow<u8>(&type_a_bytes, i);
                if (current_a_byte < current_b_byte) {
                    abort 6
                };
                if (current_a_byte > current_b_byte) {
                    is_a_larger_than_b = true;
                };
            };
            std::vector::push_back<u8>(&mut type_a_bytes, current_b_byte);
            i = i + 1;
            continue;
            abort 6
        };
        if (!is_a_larger_than_b) {
            if (std::vector::length<u8>(&type_a_bytes) < std::vector::length<u8>(&type_b_bytes)) {
                abort 6
            };
            if (std::vector::length<u8>(&type_a_bytes) == std::vector::length<u8>(&type_b_bytes)) {
                abort 3
            };
        };
        std::vector::append<u8>(&mut type_a_bytes, std::bcs::to_bytes<u32>(&tick_spacing));
        object::id_from_bytes(sui::hash::blake2b256(&type_a_bytes))
    }
    
    public fun pool_id(arg0: &PoolSimpleInfo) : ID {
        arg0.pool_id
    }
    
    public fun pool_key(arg0: &PoolSimpleInfo) : ID {
        arg0.pool_key
    }
    
    public fun pool_simple_info(arg0: &Pools, arg1: ID) : &PoolSimpleInfo {
        move_stl::linked_table::borrow<ID, PoolSimpleInfo>(&arg0.list, arg1)
    }
    
    public fun tick_spacing(arg0: &PoolSimpleInfo) : u32 {
        arg0.tick_spacing
    }
    
    // decompiled from Move bytecode v6

    #[test_only]
    public fun init_for_testing(arg0: &mut TxContext): Pools {
        let v0 = Pools {
            id    : sui::object::new(arg0), 
            list  : move_stl::linked_table::new<ID, PoolSimpleInfo>(arg0), 
            index : 0,
        };
        v0
    }
}

