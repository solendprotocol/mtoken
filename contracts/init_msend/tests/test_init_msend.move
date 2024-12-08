module init_msend::init_msend_test {
    use mtoken::mtoken::{Self};
    use sui::coin::{Self, Coin};
    use sui::clock;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, ctx};
    use sui::test_utils::{destroy, assert_eq};
    use send::send::SEND;
    use init_msend::init_msend::{mint_msend3, mint_msend6, mint_msend12, init_msend};
    use msend_series_1::msend_series_1::MSEND_SERIES_1;
    use msend_series_2::msend_series_2::MSEND_SERIES_2;
    use msend_series_3::msend_series_3::MSEND_SERIES_3;
    use mtoken::mtoken::AdminCap;

    #[test]
    fun test_e2e() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1733979600 * 1_000); // start time

        let mut send = coin::mint_for_testing<SEND>(100_000_000 * 1_000_000, scenario.ctx());
        init_msend(
            coin::create_treasury_cap_for_testing<MSEND_SERIES_1>(scenario.ctx()),
            coin::create_treasury_cap_for_testing<MSEND_SERIES_2>(scenario.ctx()),
            coin::create_treasury_cap_for_testing<MSEND_SERIES_3>(scenario.ctx()),
            &mut send,
            scenario.ctx(),
        );

        scenario.next_tx(owner);

        // check that a bunch of stuff exists
        let admin_cap_1: AdminCap<MSEND_SERIES_1, SEND, SUI> = scenario.take_from_sender();
        let admin_cap_2: AdminCap<MSEND_SERIES_2, SEND, SUI> = scenario.take_from_sender();
        let admin_cap_3: AdminCap<MSEND_SERIES_3, SEND, SUI> = scenario.take_from_sender();

        let mtoken_coin_1: Coin<MSEND_SERIES_1> = scenario.take_from_sender();
        assert!(mtoken_coin_1.value() == 25_000_000 * 1_000_000);

        let mtoken_coin_2: Coin<MSEND_SERIES_2> = scenario.take_from_sender();
        assert!(mtoken_coin_2.value() == 6_875_000 * 1_000_000);

        let mtoken_coin_3: Coin<MSEND_SERIES_3> = scenario.take_from_sender();
        assert!(mtoken_coin_3.value() == 15_000_000 * 1_000_000);

        let manager_1: mtoken::VestingManager<MSEND_SERIES_1, SEND, SUI> = scenario.take_shared();
        let manager_2: mtoken::VestingManager<MSEND_SERIES_2, SEND, SUI> = scenario.take_shared();
        let manager_3: mtoken::VestingManager<MSEND_SERIES_3, SEND, SUI> = scenario.take_shared();

        assert_eq(manager_1.start_time_s(), 1733979600);
        assert_eq(manager_1.end_time_s(), 1741752000);
        assert_eq(manager_1.start_penalty_numerator(), 250);

        assert_eq(manager_2.start_time_s(), 1733979600);
        assert_eq(manager_2.end_time_s(), 1749700800);
        assert_eq(manager_2.start_penalty_numerator(), 500);

        assert_eq(manager_3.start_time_s(), 1733979600);
        assert_eq(manager_3.end_time_s(), 1765515600);
        assert_eq(manager_3.start_penalty_numerator(), 375);

        assert_eq(send.value(), 53_125_000 * 1_000_000);

        scenario.return_to_sender(admin_cap_1);
        scenario.return_to_sender(admin_cap_2);
        scenario.return_to_sender(admin_cap_3);

        scenario.return_to_sender(mtoken_coin_1);
        scenario.return_to_sender(mtoken_coin_2);
        scenario.return_to_sender(mtoken_coin_3);

        test_scenario::return_shared(manager_1);
        test_scenario::return_shared(manager_2);
        test_scenario::return_shared(manager_3);

        destroy(send);
        destroy(clock);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_3msend() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1733979600 * 1_000);
        
        let (admin_cap, mut manager, mtoken_coin) = mint_msend3(
            coin::create_treasury_cap_for_testing<MSEND_SERIES_1>(scenario.ctx()),
            coin::mint_for_testing<SEND>(100 * 10_u64.pow(6), scenario.ctx()),
            ctx(&mut scenario),
        );

        let msend_coin = coin::mint_for_testing<MSEND_SERIES_1>(100 * 10_u64.pow(6), ctx(&mut scenario));
        let mut sui_coin = coin::mint_for_testing<SUI>(100 * 10_u64.pow(9), ctx(&mut scenario));

        let send = mtoken::redeem_mtokens<MSEND_SERIES_1, SEND, SUI>(
            &mut manager,
            msend_coin,
            &mut sui_coin,
            &clock,
            ctx(&mut scenario),
        );

        assert_eq(send.value() / 10_u64.pow(6), 100);
        assert_eq(sui_coin.value() / 10_u64.pow(9), 75); // 100 -25

        destroy(send);
        destroy(sui_coin);
        destroy(clock);
        destroy(mtoken_coin);
        destroy(admin_cap);
        destroy(manager);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_6msend() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1733979600 * 1_000);

        let (admin_cap, mut manager, mtoken_coin) = mint_msend6(
            coin::create_treasury_cap_for_testing<MSEND_SERIES_2>(scenario.ctx()),
            coin::mint_for_testing<SEND>(100 * 10_u64.pow(6), scenario.ctx()),
            ctx(&mut scenario),
        );

        let msend_coin = coin::mint_for_testing<MSEND_SERIES_2>(100 * 10_u64.pow(6), ctx(&mut scenario));
        let mut sui_coin = coin::mint_for_testing<SUI>(100 * 10_u64.pow(9), ctx(&mut scenario));

        let send = mtoken::redeem_mtokens<MSEND_SERIES_2, SEND, SUI>(
            &mut manager,
            msend_coin,
            &mut sui_coin,
            &clock,
            ctx(&mut scenario),
        );

        assert_eq(send.value() / 10_u64.pow(6), 100);
        assert_eq(sui_coin.value() / 10_u64.pow(9), 50); // 100 - 50

        destroy(send);
        destroy(sui_coin);
        destroy(clock);
        destroy(mtoken_coin);
        destroy(admin_cap);
        destroy(manager);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_12msend() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1733979600 * 1_000);

        let (admin_cap, mut manager, mtoken_coin) = mint_msend12(
            coin::create_treasury_cap_for_testing<MSEND_SERIES_3>(scenario.ctx()),
            coin::mint_for_testing<SEND>(1000 * 10_u64.pow(6), scenario.ctx()),
            ctx(&mut scenario),
        );

        let msend_coin = coin::mint_for_testing<MSEND_SERIES_3>(1_000 * 10_u64.pow(6), ctx(&mut scenario));
        let mut sui_coin = coin::mint_for_testing<SUI>(1_000 * 10_u64.pow(9), ctx(&mut scenario));

        let send = mtoken::redeem_mtokens<MSEND_SERIES_3, SEND, SUI>(
            &mut manager,
            msend_coin,
            &mut sui_coin,
            &clock,
            ctx(&mut scenario),
        );

        assert_eq(send.value() / 10_u64.pow(6), 1_000);
        assert_eq(sui_coin.value() / 10_u64.pow(9), 625); // 1000 - 375

        destroy(send);
        destroy(sui_coin);
        destroy(clock);
        destroy(mtoken_coin);
        destroy(admin_cap);
        destroy(manager);

        test_scenario::end(scenario);
    }
}
