#[test_only]
module mtoken::msend_test {
    use std::string::utf8;
    use sui::clock;
    use sui::balance;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::sui::SUI;
    use sui::test_utils::{destroy};
    use sui::test_scenario::{Self, Scenario, ctx};
    use sui::test_utils::{assert_eq};
    use cetus_clmm::factory;
    use cetus_clmm::pool::{Pool as CetusPool};
    use cetus_clmm::config;
    use sui::tx_context::sender;
    use mtoken::send::{Self, SEND};
    use mtoken::msend::{Self, MSEND};
    use mtoken::mtoken;

    const START_TIME_S: u64 = 1733228602;
    const END_TIME_S: u64 = 1734006202;

    public fun send_decimals(val: u64): u64 {
        val * 1_000_000
    }

    public fun setup_cetus_pool_split_liquidity_2(
        scenario: &mut Scenario,
    ): (
        cetus_clmm::pool::Pool<SEND, SUI>,
        cetus_clmm::config::GlobalConfig,
        cetus_clmm::config::AdminCap,
        cetus_clmm::position::Position,
    ) {
        let owner = sender(ctx(scenario));
        let clock = clock::create_for_testing(ctx(scenario));

        // Supply allocated
        let send_liquidity_amount = send_decimals(20_000_000_000);
        
        let tick_spacing = 200_u32;
        
        let sqrt_price = cetus_clmm::tick_math::get_sqrt_price_at_tick(
            integer_mate::i32::from(46000) // 0.1
        );

        let mut registry = factory::init_for_testing(ctx(scenario));
        let (mut config, admin_cap) = config::init_for_testing(ctx(scenario));
        let fee_rate = 10000;
        config::add_fee_tier(&mut config, tick_spacing, fee_rate, ctx(scenario));

        // Prepare coins
        let send = coin::mint_for_testing<SEND>(send_liquidity_amount, ctx(scenario));

        // Ticks
        let tick_a1 = 23000; // 0.01
        let tick_a2 = 69000; // 1.0

        let (position, coin_meme, coin_sui) = factory::create_pool_with_liquidity<SEND, SUI>(
            &mut registry,
            &config,
            tick_spacing,
            sqrt_price, // current_sqrt_price
            utf8(b"hello"),
            tick_a1,
            tick_a2,
            send,
            coin::mint_for_testing(1_000_000_000, ctx(scenario)),
            send_liquidity_amount,
            0,
            true, // from_a
            &clock,
            ctx(scenario),
        );

        destroy(coin_meme);
        destroy(coin_sui);

        test_scenario::next_tx(scenario, owner);
        let pool: CetusPool<SEND, SUI> = test_scenario::take_shared(scenario);

        destroy(clock);
        destroy(registry);

        (pool, config, admin_cap, position)
    }
    
    public fun setup_cetus_pool_split_liquidity(
        scenario: &mut Scenario,
    ): (
        cetus_clmm::pool::Pool<SEND, SUI>,
        cetus_clmm::config::GlobalConfig,
        cetus_clmm::config::AdminCap,
        cetus_clmm::position::Position,
    ) {
        let owner = sender(ctx(scenario));
        let clock = clock::create_for_testing(ctx(scenario));

        // Supply allocated
        let send_liquidity_amount = send_decimals(20_000_000_000);
        
        let tick_spacing = 200_u32;
        
        let sqrt_price = cetus_clmm::tick_math::get_sqrt_price_at_tick(
            integer_mate::i32::from(46000) // 0.1
        );

        let mut registry = factory::init_for_testing(ctx(scenario));
        let (mut config, admin_cap) = config::init_for_testing(ctx(scenario));
        let fee_rate = 10000;
        config::add_fee_tier(&mut config, tick_spacing, fee_rate, ctx(scenario));

        // Prepare coins
        let send = coin::mint_for_testing<SEND>(send_liquidity_amount, ctx(scenario));

        // Ticks
        let tick_a1 = 39000; // 0.05
        let tick_a2 = 69000; // 1.0

        let (position, coin_meme, coin_sui) = factory::create_pool_with_liquidity<SEND, SUI>(
            &mut registry,
            &config,
            tick_spacing,
            sqrt_price, // current_sqrt_price
            utf8(b"hello"),
            tick_a1,
            tick_a2,
            send,
            coin::mint_for_testing(859622001237312227, ctx(scenario)),
            send_liquidity_amount,
            859622001237312227,
            true, // from_a
            &clock,
            ctx(scenario),
        );

        destroy(coin_meme);
        destroy(coin_sui);

        test_scenario::next_tx(scenario, owner);
        let pool: CetusPool<SEND, SUI> = test_scenario::take_shared(scenario);

        destroy(clock);
        destroy(registry);

        (pool, config, admin_cap, position)
    }

    #[test]
    public fun mint_mtokens() {
        let mut scenario = test_scenario::begin(@0x10);

        send::init_for_testing(scenario.ctx());
        scenario.next_tx(@0x10);
        let send: Coin<SEND> = scenario.take_from_address(@0x10);

        msend::init_for_testing(scenario.ctx());
        scenario.next_tx(@0x10);

        let treasury_cap: TreasuryCap<MSEND> = scenario.take_from_address(@0x10);

        let (admin_cap, manager, msend) = mtoken::mint_mtokens<MSEND, SEND, SUI>(
            treasury_cap,
            send,
            10, // start_penalty_numerator
            1, // end_penalty_numerator
            100_000, // penalty_denominator
            START_TIME_S, // start_time_s
            END_TIME_S, // end_time_s
            scenario.ctx(),
        );

        transfer::public_share_object(manager);
        transfer::public_transfer(admin_cap, @0x10);
        transfer::public_transfer(msend, @0x10);

        scenario.end();
    }
    
    #[test]
    public fun claim_send() {
        let mut scenario = test_scenario::begin(@0x10);
        let mut clock = clock::create_for_testing(scenario.ctx());
        clock.set_for_testing(START_TIME_S * 1000);

        send::init_for_testing(scenario.ctx());
        scenario.next_tx(@0x10);
        let send: Coin<SEND> = scenario.take_from_address(@0x10);

        msend::init_for_testing(scenario.ctx());
        scenario.next_tx(@0x10);

        let treasury_cap: TreasuryCap<MSEND> = scenario.take_from_address(@0x10);

        let send_value = send.value();
        let (admin_cap, mut manager, mut msend) = mtoken::mint_mtokens<MSEND, SEND, SUI>(
            treasury_cap,
            send,
            10, // start_penalty_numerator
            1, // end_penalty_numerator
            100_000, // penalty_denominator
            START_TIME_S, // start_time_s
            END_TIME_S, // end_time_s
            scenario.ctx(),
        );
        assert!(send_value == msend.value(), 0);

        scenario.next_tx(@0x10);

        let msend_to_redeem = msend.split(1_000_000, scenario.ctx());
        let mut penalty_coin = coin::mint_for_testing<SUI>(100, scenario.ctx());

        let send = manager.redeem_mtokens(
            msend_to_redeem,
            &mut penalty_coin,
            &clock,
            scenario.ctx(),
        );

        assert!(penalty_coin.value() == 0, 1);
        assert!(send.value() == 1_000_000, 2);

        destroy(manager);
        destroy(admin_cap);
        destroy(penalty_coin);
        destroy(msend);
        destroy(send);
        destroy(clock);

        scenario.end();
    }

    #[test]
    public fun test_flash_loan() {
        let mut scenario = test_scenario::begin(@0x10);
        let mut clock = clock::create_for_testing(scenario.ctx());
        clock.set_for_testing(START_TIME_S * 1000);

        send::init_for_testing(scenario.ctx());
        scenario.next_tx(@0x10);
        let send: Coin<SEND> = scenario.take_from_address(@0x10);

        msend::init_for_testing(scenario.ctx());
        scenario.next_tx(@0x10);

        let treasury_cap: TreasuryCap<MSEND> = scenario.take_from_address(@0x10);

        let send_value = send.value();
        
        let (admin_cap, mut manager, mut msend) = mtoken::mint_mtokens<MSEND, SEND, SUI>(
            treasury_cap,
            send,
            10, // start_penalty_numerator
            1, // end_penalty_numerator
            100_000, // penalty_denominator
            START_TIME_S, // start_time_s
            END_TIME_S, // end_time_s
            scenario.ctx(),
        );

        assert!(send_value == msend.value(), 0);

        scenario.next_tx(@0x10);

        let msend_to_redeem = msend.split(1_000_000, scenario.ctx());

        let (mut pool, config, pool_admin_cap, position) = setup_cetus_pool_split_liquidity(&mut scenario);

        let min_price = cetus_clmm::tick_math::get_sqrt_price_at_tick(
            integer_mate::i32::from(23000) // 0.01
        );

        let (mut send_bal, sui_bal, receipt) = cetus_clmm::pool::flash_swap(
            &config,
            &mut pool,
            true, // a2b
            false, // by amount_in
            100, // amount
            min_price,
            &clock,
        );

        assert_eq(send_bal.value(), 0);
        assert_eq(sui_bal.value(), 100);

        let mut penalty_coin = coin::from_balance(sui_bal, scenario.ctx());

        let mut send = manager.redeem_mtokens(
            msend_to_redeem,
            &mut penalty_coin,
            &clock,
            scenario.ctx(),
        );

        assert!(penalty_coin.value() == 0, 1);
        assert!(send.value() == 1_000_000, 2);

        send_bal.join(send.split(receipt.swap_pay_amount(), scenario.ctx()).into_balance());

        cetus_clmm::pool::repay_flash_swap(&config, &mut pool, send_bal, balance::zero(), receipt);

        destroy(pool);
        destroy(config);
        destroy(pool_admin_cap);
        destroy(position);

        destroy(manager);
        destroy(admin_cap);
        destroy(penalty_coin);
        destroy(msend);
        destroy(send);
        destroy(clock);

        scenario.end();
    }
}