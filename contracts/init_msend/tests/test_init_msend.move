module init_msend::init_msend_test {
    use mtoken::mtoken::{Self};
    use sui::coin;
    use sui::clock;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, ctx};
    use sui::test_utils::{destroy, assert_eq};
    use send::send::SEND;
    use init_msend::init_msend::{mint_msend3, mint_msend6, mint_msend12};
    use msend_3_month::msend_3_month::MSEND_3_MONTH;
    use msend_6_month::msend_6_month::MSEND_6_MONTH;
    use msend_12_month::msend_12_month::MSEND_12_MONTH;
    
    #[test]
    fun test_3msend() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1733979600 * 1_000);
        
        let (admin_cap, mut manager, mtoken_coin) = mint_msend3(
            coin::create_treasury_cap_for_testing<MSEND_3_MONTH>(scenario.ctx()),
            coin::mint_for_testing<SEND>(100 * 10_u64.pow(6), scenario.ctx()),
            ctx(&mut scenario),
        );

        let msend_coin = coin::mint_for_testing<MSEND_3_MONTH>(100 * 10_u64.pow(6), ctx(&mut scenario));
        let mut sui_coin = coin::mint_for_testing<SUI>(100 * 10_u64.pow(9), ctx(&mut scenario));

        let send = mtoken::redeem_mtokens<MSEND_3_MONTH, SEND, SUI>(
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
            coin::create_treasury_cap_for_testing<MSEND_6_MONTH>(scenario.ctx()),
            coin::mint_for_testing<SEND>(100 * 10_u64.pow(6), scenario.ctx()),
            ctx(&mut scenario),
        );

        let msend_coin = coin::mint_for_testing<MSEND_6_MONTH>(100 * 10_u64.pow(6), ctx(&mut scenario));
        let mut sui_coin = coin::mint_for_testing<SUI>(100 * 10_u64.pow(9), ctx(&mut scenario));

        let send = mtoken::redeem_mtokens<MSEND_6_MONTH, SEND, SUI>(
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
            coin::create_treasury_cap_for_testing<MSEND_12_MONTH>(scenario.ctx()),
            coin::mint_for_testing<SEND>(1000 * 10_u64.pow(6), scenario.ctx()),
            ctx(&mut scenario),
        );

        let msend_coin = coin::mint_for_testing<MSEND_12_MONTH>(1_000 * 10_u64.pow(6), ctx(&mut scenario));
        let mut sui_coin = coin::mint_for_testing<SUI>(1_000 * 10_u64.pow(9), ctx(&mut scenario));

        let send = mtoken::redeem_mtokens<MSEND_12_MONTH, SEND, SUI>(
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
