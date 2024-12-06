#[test_only]
module mtoken::init_tests {
    use mtoken::mtoken::{Self, AdminCap, VestingManager};
    use sui::coin::{Self, Coin};
    use sui::clock;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, ctx};
    use sui::test_utils::{destroy, assert_eq};
    use send::send::SEND;
    use msend_3_month::msend_3_month::MSEND_3_MONTH;
    use msend_6_month::msend_6_month::MSEND_6_MONTH;
    use msend_12_month::msend_12_month::MSEND_12_MONTH;

    public fun mint_3msend(
        vesting_coin: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_3_MONTH, SEND, SUI>, VestingManager<MSEND_3_MONTH, SEND, SUI>, Coin<MSEND_3_MONTH>) {
        let treasury = coin::create_treasury_cap_for_testing<MSEND_3_MONTH>(ctx);

        let start_penalty_numerator = 250; // 0.25*10^(9-6) = 1_000 / 4 = 1 * 10^3 / 4
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;

        let (admin_cap, manager, mtoken_coin) = mtoken::mint_mtokens(
            treasury,
            vesting_coin,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            1733508512,
            1741802912,
            ctx,
        );

        (admin_cap, manager, mtoken_coin)
    }
    
    public fun mint_6msend(
        vesting_coin: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_6_MONTH, SEND, SUI>, VestingManager<MSEND_6_MONTH, SEND, SUI>, Coin<MSEND_6_MONTH>) {
        let treasury = coin::create_treasury_cap_for_testing<MSEND_6_MONTH>(ctx);

        let start_penalty_numerator = 500;
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;

        let (admin_cap, manager, mtoken_coin) = mtoken::mint_mtokens(
            treasury,
            vesting_coin,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            1733508512,
            1749748112,
            ctx,
        );

        (admin_cap, manager, mtoken_coin)
    }
    
    public fun mint_12msend(
        vesting_coin: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_12_MONTH, SEND, SUI>, VestingManager<MSEND_12_MONTH, SEND, SUI>, Coin<MSEND_12_MONTH>) {
        let treasury = coin::create_treasury_cap_for_testing<MSEND_12_MONTH>(ctx);

        let start_penalty_numerator = 375;
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;

        let (admin_cap, manager, mtoken_coin) = mtoken::mint_mtokens(
            treasury,
            vesting_coin,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            1733508512,
            1749748112,
            ctx,
        );

        (admin_cap, manager, mtoken_coin)
    }
    
    #[test]
    fun test_3msend() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1733508512000);

        let underlying_coin = coin::mint_for_testing<SEND>(100 * 10_u64.pow(6), ctx(&mut scenario));
        
        let (admin_cap, mut manager, mtoken_coin) = mint_3msend(
            underlying_coin,
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
        clock.set_for_testing(1733508512000);

        let underlying_coin = coin::mint_for_testing<SEND>(100 * 10_u64.pow(6), ctx(&mut scenario));
        
        let (admin_cap, mut manager, mtoken_coin) = mint_6msend(
            underlying_coin,
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
        clock.set_for_testing(1733508512000);

        let underlying_coin = coin::mint_for_testing<SEND>(1_000 * 10_u64.pow(6), ctx(&mut scenario));
        
        let (admin_cap, mut manager, mtoken_coin) = mint_12msend(
            underlying_coin,
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
