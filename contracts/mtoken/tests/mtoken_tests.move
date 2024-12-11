#[test_only]
module mtoken::mtoken_tests {
    use std::ascii;
    use std::option::none;
    use mtoken::mtoken::{Self, AdminCap, VestingManager};
    use mtoken::underlying::{Self, UNDERLYING};
    use mtoken::vest::{VEST};
    use sui::coin::{Self, Coin, CoinMetadata};
    use sui::clock;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, ctx};
    use sui::test_utils::{create_one_time_witness, destroy};
    use std::string::{Self};

    public fun mint_mtokens_for_test<MToken: drop, Vesting, Penalty>(
        otw: MToken,
        vesting_coin: Coin<Vesting>,
        coin_meta: &CoinMetadata<Vesting>,
        start_penalty_numerator: u64,
        end_penalty_numerator: u64,
        penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
        ctx: &mut TxContext,
    ): (AdminCap<MToken, Vesting, Penalty>, VestingManager<MToken, Vesting, Penalty>, Coin<MToken>) {
        let mut name_ticker = ascii::string(b"WANG_");
        name_ticker.append(coin_meta.get_symbol());

        let mut description = ascii::string(b"WANG Coin for ");
        description.append(coin_meta.get_symbol());

        let (treasury_cap, metadata) = coin::create_currency(
            otw,
            coin_meta.get_decimals(),
            name_ticker.into_bytes(),
            name_ticker.into_bytes(),
            description.into_bytes(),
            none(),
            ctx,
        );

        let (admin_cap, manager, mtoken_coin) = mtoken::mint_mtokens(
            treasury_cap,
            vesting_coin,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            start_time_s,
            end_time_s,
            ctx,
        );

        transfer::public_share_object(metadata);

        (admin_cap, manager, mtoken_coin)
    }
    
    #[test]
    fun test_create_mtoken_coin() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));
        
        let (admin_cap, manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        destroy(metadata);
        destroy(clock);
        destroy(mtoken_coin);
        destroy(treasury_cap);
        destroy(admin_cap);
        destroy(manager);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_immediate_redeem() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 800, 0);

        let underlying_coin = treasury_cap.mint(1_000, ctx(&mut scenario));
        let mtoken_coin = mtoken::mint_more_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            &admin_cap,
            underlying_coin,
            ctx(&mut scenario),
        );
        assert!(mtoken_coin.value() == 1_000, 0);

        destroy(unvested_coin);
        destroy(mtoken_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
   
    #[test]
    fun test_mid_time_redeem() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        clock.increment_for_testing(50 * 1_000);

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 400, 0);

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_redeem_at_maturity() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        clock.increment_for_testing(100 * 1_000);

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );
        assert!(penalty_sui.value() == 10_000 - 0, 0);

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = mtoken::EEndTimeBeforeStartTime)]
    fun test_fail_end_time_before_start_time() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000 + 100,
            (clock.timestamp_ms() / 1_000),
            ctx(&mut scenario),
        );

        destroy(mtoken_coin);
        destroy(clock);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code = mtoken::ERedeemingBeforeStartTime)]
    fun test_fail_redeem_before_start_time() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1000);

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        destroy(clock);

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        let clock = clock::create_for_testing(ctx(&mut scenario));

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        destroy(unvested_coin);
        destroy(penalty_sui);
        destroy(clock);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = mtoken::ENotEnoughPenaltyFunds)]
    fun test_fail_not_enough_penalty_funds() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(0, ctx(&mut scenario));

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_collect() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 800, 0);

        let penalty_coin = manager.collect_penalties(&admin_cap, ctx(&mut scenario));

        assert!(penalty_coin.value() == 800, 0);

        destroy(penalty_coin);
        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code = mtoken::EIncorrectAdminCap)]
    fun test_fail_collect_wrong_admin_cap() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (fake_admin_cap, fake_manager, fake_mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, vesting_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            0,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 800, 0);

        let penalty_coin = manager.collect_penalties(&fake_admin_cap, ctx(&mut scenario));

        assert!(penalty_coin.value() == 800, 0);

        destroy(penalty_coin);
        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);
        destroy(fake_admin_cap);
        destroy(fake_manager);
        destroy(fake_mtoken_coin);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_immediate_redeem_with_end_price() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            5,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 800, 0);

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
   
    #[test]
    fun test_mid_time_redeem_with_end_price() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            5,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        clock.increment_for_testing(50 * 1_000);

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 600, 0);

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_mid_time_redeem_with_end_price_2() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            5,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        clock.increment_for_testing(75 * 1_000);

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 500, 0);

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_redeem_at_maturity_with_end_price() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            5,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        clock.increment_for_testing(100 * 1_000);

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );
        assert!(penalty_sui.value() == 10_000 - 400, 0);

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }

    #[test]
    #[expected_failure(abort_code = mtoken::EMTokenSupplyNotZero)]
    fun test_fail_create_mtoken_coin_non_zero_supply() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let start_penalty_numerator = 10;
        let end_penalty_numerator = 0;
        let penalty_denominator = 100;
        let start_time_s = clock.timestamp_ms() / 1_000;
        let end_time_s = (clock.timestamp_ms() / 1_000) + 100;

        let mut name_ticker = ascii::string(b"WANG_");
        name_ticker.append(metadata.get_symbol());

        let mut description = ascii::string(b"WANG Coin for ");
        description.append(metadata.get_symbol());

        let (mut mtoken_treasury_cap, mtoken_metadata) = coin::create_currency(
            create_one_time_witness<VEST>(),
            metadata.get_decimals(),
            name_ticker.into_bytes(),
            name_ticker.into_bytes(),
            description.into_bytes(),
            none(),
            scenario.ctx(),
        );

        destroy(metadata);

        let extra_coin = mtoken_treasury_cap.mint(1, scenario.ctx());

        let (admin_cap, manager, mtoken_coin) = mtoken::mint_mtokens<VEST, UNDERLYING, SUI>(
            mtoken_treasury_cap,
            underlying_coin,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            start_time_s,
            end_time_s,
            scenario.ctx(),
        );

        destroy(clock);
        destroy(extra_coin);
        destroy(treasury_cap);
        destroy(mtoken_metadata);
        destroy(mtoken_coin);
        destroy(admin_cap);
        destroy(manager);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_set_penalty_and_immediate_redeem() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, mtoken_coin) = mint_mtokens_for_test<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            100,
            10,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );
        scenario.next_tx(owner);

        let mut mtoken_metadata: CoinMetadata<VEST> = scenario.take_shared();
        manager.set_params(
            &admin_cap,
            10,
            0,
            100,
            &mut mtoken_metadata,
            string::utf8(b"asdfasdfasdf"),
        );

        assert!(mtoken_metadata.get_description() == string::utf8(b"asdfasdfasdf"), 0);
        test_scenario::return_shared(mtoken_metadata);

        assert!(manager.start_penalty_numerator() == 10, 0);
        assert!(manager.end_penalty_numerator() == 0, 0);
        assert!(manager.penalty_denominator() == 100, 0);

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        let unvested_coin = mtoken::redeem_mtokens<VEST, UNDERLYING, SUI>(
            &mut manager,
            mtoken_coin,
            &mut penalty_sui,
            &clock,
            ctx(&mut scenario),
        );

        assert!(penalty_sui.value() == 10_000 - 800, 0);

        destroy(unvested_coin);
        destroy(clock);
        destroy(penalty_sui);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
}
