#[test_only]
module vesting::vesting_tests {
    use vesting::vesting::{Self};
    use vesting::underlying::{Self, UNDERLYING};
    use vesting::vest::{VEST};
    use sui::coin::{Self, Coin};
    use sui::clock;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, ctx};
    use sui::test_utils::{create_one_time_witness, destroy};
    
    #[test]
    fun test_create_vesting_coin() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));
        let (admin_cap, manager, vesting_coin) = vesting::mint_vesting_coin<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        destroy(metadata);
        destroy(clock);
        destroy(vesting_coin);
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_vesting_coin<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        // let withdraw_amount = vested_coin.value();
        let unvested_coin = vesting::redeem<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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
    fun test_mid_time_redeem() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_vesting_coin<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        clock.increment_for_testing(50 * 1_000);

        let unvested_coin = vesting::redeem<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_vesting_coin<VEST, UNDERLYING, SUI>(
            create_one_time_witness<VEST>(),
            underlying_coin,
            &metadata,
            10,
            100,
            clock.timestamp_ms() / 1_000,
            (clock.timestamp_ms() / 1_000) + 100,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut penalty_sui: Coin<SUI> = coin::mint_for_testing(10_000, ctx(&mut scenario));

        clock.increment_for_testing(100 * 1_000);

        let unvested_coin = vesting::redeem<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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
    
    // #[test]
    // fun test_redeem_at_maturity() {
    //     let owner = @0x10;
    //     let mut scenario = test_scenario::begin(owner);

    //     let (mut manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

    //     let (mut treasury_cap, metadata) = vested_coin::create_currency(ctx(&mut scenario));

    //     vesting::create_vesting_coin(
    //         create_one_time_witness<OPTION_COIN>(),
    //         &mut manager,
    //         &metadata,
    //         ctx(&mut scenario),
    //     );

    //     scenario.next_tx(owner);

    //     let vesting_meta: CoinMetadata<OPTION_COIN> = scenario.take_immutable();

    //     assert!(
    //         manager.fields().contains(
    //         vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
    //     ), 0);

    //     let _treasury_cap: &TreasuryCap<OPTION_COIN> = manager.fields().borrow(
    //         vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
    //     );

    //     let mut clock = clock::create_for_testing(ctx(&mut scenario));
    //     let coins_to_vest = treasury_cap.mint(10_000, ctx(&mut scenario));

    //     let (mut vested_coin, mut penalty_cap) = vesting::mint_vesting_coin<OPTION_COIN,VESTED_COIN, SUI>(
    //         &mut manager,
    //         1_000,
    //         clock.timestamp_ms() / 1_000, // start_time_s
    //         (clock.timestamp_ms() / 1_000) + 100, // end_time_s
    //         coins_to_vest,
    //         ctx(&mut scenario),
    //     );

    //     // Redeem at maturity
    //     let mut sui: Coin<SUI> = coin::mint_for_testing(5_000, ctx(&mut scenario));
    //     clock.increment_for_testing(100 * 1_000);

    //     let withdraw_amount = vested_coin.value();
    //     let unvested_coin = vesting::redeem<OPTION_COIN,VESTED_COIN, SUI>(
    //         &mut manager,
    //         &mut vested_coin,
    //         &mut sui,
    //         &mut penalty_cap,
    //         withdraw_amount,
    //         &clock,
    //         ctx(&mut scenario),
    //     );

    //     assert!(unvested_coin.value() == withdraw_amount, 0);
    //     assert!(vested_coin.value() == 0, 0);
    //     assert!(sui.value() == 5_000 - 0, 0);
    //     assert!(penalty_cap.amount() == 0, 0);

    //     vesting::try_destroy_empty(penalty_cap, ctx(&mut scenario));

    //     destroy(unvested_coin);
    //     destroy(vested_coin);
    //     destroy(clock);
    //     destroy(sui);
    //     destroy(metadata);
    //     destroy(vesting_meta);
    //     destroy(treasury_cap);
    //     destroy(manager);
    //     destroy(admin_cap);

    //     test_scenario::end(scenario);
    // }
    
    // #[test]
    // fun test_redeem_mid_term() {
    //     let owner = @0x10;
    //     let mut scenario = test_scenario::begin(owner);

    //     let (mut manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

    //     let (mut treasury_cap, metadata) = vested_coin::create_currency(ctx(&mut scenario));

    //     vesting::create_vesting_coin(
    //         create_one_time_witness<OPTION_COIN>(),
    //         &mut manager,
    //         &metadata,
    //         ctx(&mut scenario),
    //     );

    //     scenario.next_tx(owner);

    //     let vesting_meta: CoinMetadata<OPTION_COIN> = scenario.take_immutable();

    //     assert!(
    //         manager.fields().contains(
    //         vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
    //     ), 0);

    //     let _treasury_cap: &TreasuryCap<OPTION_COIN> = manager.fields().borrow(
    //         vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
    //     );

    //     let mut clock = clock::create_for_testing(ctx(&mut scenario));
    //     let coins_to_vest = treasury_cap.mint(10_000, ctx(&mut scenario));

    //     let penalty_amount = 1_000;
    //     let (mut vested_coin, mut penalty_cap) = vesting::mint_vesting_coin<OPTION_COIN,VESTED_COIN, SUI>(
    //         &mut manager,
    //         penalty_amount,
    //         clock.timestamp_ms() / 1_000, // start_time_s
    //         (clock.timestamp_ms() / 1_000) + 100, // end_time_s
    //         coins_to_vest,
    //         ctx(&mut scenario),
    //     );

    //     // Redeem at 25% of time passed
    //     let mut sui: Coin<SUI> = coin::mint_for_testing(5_000, ctx(&mut scenario));
    //     clock.increment_for_testing(25 * 1_000);

    //     let withdraw_amount = vested_coin.value();
    //     let unvested_coin = vesting::redeem<OPTION_COIN,VESTED_COIN, SUI>(
    //         &mut manager,
    //         &mut vested_coin,
    //         &mut sui,
    //         &mut penalty_cap,
    //         withdraw_amount,
    //         &clock,
    //         ctx(&mut scenario),
    //     );

    //     assert_eq(unvested_coin.value(), withdraw_amount);
    //     assert_eq(vested_coin.value(), 0);
    //     assert_eq(sui.value(), ((5_000 * 100) - (penalty_amount * (100 - 25))) / 100);
    //     assert_eq(penalty_cap.amount(), 0);

    //     vesting::try_destroy_empty(penalty_cap, ctx(&mut scenario));

    //     destroy(unvested_coin);
    //     destroy(vested_coin);
    //     destroy(clock);
    //     destroy(sui);
    //     destroy(metadata);
    //     destroy(vesting_meta);
    //     destroy(treasury_cap);
    //     destroy(manager);
    //     destroy(admin_cap);

    //     test_scenario::end(scenario);
    // }
    
    // #[test]
    // fun test_partial_redeems() {
    //     let owner = @0x10;
    //     let mut scenario = test_scenario::begin(owner);

    //     let (mut manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

    //     let (mut treasury_cap, metadata) = vested_coin::create_currency(ctx(&mut scenario));

    //     vesting::create_vesting_coin(
    //         create_one_time_witness<OPTION_COIN>(),
    //         &mut manager,
    //         &metadata,
    //         ctx(&mut scenario),
    //     );

    //     scenario.next_tx(owner);

    //     let vesting_meta: CoinMetadata<OPTION_COIN> = scenario.take_immutable();

    //     assert!(
    //         manager.fields().contains(
    //         vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
    //     ), 0);

    //     let _treasury_cap: &TreasuryCap<OPTION_COIN> = manager.fields().borrow(
    //         vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
    //     );

    //     let mut clock = clock::create_for_testing(ctx(&mut scenario));
    //     let coins_to_vest = treasury_cap.mint(10_000, ctx(&mut scenario));

    //     let penalty_amount = 1_000;
    //     let (mut vested_coin, mut penalty_cap) = vesting::mint_vesting_coin<OPTION_COIN,VESTED_COIN, SUI>(
    //         &mut manager,
    //         penalty_amount,
    //         clock.timestamp_ms() / 1_000, // start_time_s
    //         (clock.timestamp_ms() / 1_000) + 100, // end_time_s
    //         coins_to_vest,
    //         ctx(&mut scenario),
    //     );

    //     // Redeem at 25% of time passed
    //     let mut sui: Coin<SUI> = coin::mint_for_testing(5_000, ctx(&mut scenario));
        
    //     let withdraw_amount = 2_000; // 20%
    //     let unvested_coin = vesting::redeem<OPTION_COIN,VESTED_COIN, SUI>(
    //         &mut manager,
    //         &mut vested_coin,
    //         &mut sui,
    //         &mut penalty_cap,
    //         withdraw_amount,
    //         &clock,
    //         ctx(&mut scenario),
    //     );

    //     let expected_penalty = (5_000 * 10_000 - penalty_amount * 2_000) / 10_000;
    //     let expected_vested_amount = 10_000 - 2_000;
    //     let remaining_to_withdraw = 10_000 - 2_000;
    //     let remaining_start_penalty = penalty_amount * 8_000 / 10_000;

    //     assert_eq(unvested_coin.value(), withdraw_amount);
    //     assert_eq(vested_coin.value(), expected_vested_amount);
    //     assert_eq(sui.value(), expected_penalty); // subtract the corresponding penalty
    //     assert_eq(penalty_cap.amount(), remaining_to_withdraw);
    //     assert_eq(penalty_cap.start_penalty(), remaining_start_penalty); // Remove from the penalty the 20% withdrawn
    //     destroy(unvested_coin);

    //     clock.increment_for_testing(50 * 1_000);
    //     // assert_eq(sui.value(), ((5_000 * 100) - (penalty_amount * (100 - 25))) / 100);

    //     let withdraw_amount = 2_000; // 20%
    //     let unvested_coin = vesting::redeem<OPTION_COIN,VESTED_COIN, SUI>(
    //         &mut manager,
    //         &mut vested_coin,
    //         &mut sui,
    //         &mut penalty_cap,
    //         withdraw_amount,
    //         &clock,
    //         ctx(&mut scenario),
    //     );

    //     let expected_vested_amount = expected_vested_amount - 2_000;
    //     let expected_penalty = (5_000 * 10_000 - penalty_amount * 2_000) / 10_000;
    //     let remaining_to_withdraw = remaining_to_withdraw - 2_000;
    //     let remaining_start_penalty = penalty_amount * 8_000 / 10_000;

    //     assert_eq(unvested_coin.value(), withdraw_amount);
    //     assert_eq(vested_coin.value(), expected_vested_amount);
    //     assert_eq(penalty_cap.amount(), remaining_to_withdraw);
    //     // TODO: continue
    //     // assert_eq(sui.value(), (5_000 * 10_000 - penalty_amount * 2_000) / 10_000); // subtract the corresponding penalty
    //     // assert_eq(penalty_cap.start_penalty(), penalty_amount * 8_000 / 10_000); // Remove from the penalty the 20% withdrawn
    //     destroy(unvested_coin);

    //     vesting::try_destroy_empty(penalty_cap, ctx(&mut scenario));

        
    //     destroy(vested_coin);
    //     destroy(clock);
    //     destroy(sui);
    //     destroy(metadata);
    //     destroy(vesting_meta);
    //     destroy(treasury_cap);
    //     destroy(manager);
    //     destroy(admin_cap);

    //     test_scenario::end(scenario);
    // }

    

    // #[test, expected_failure(abort_code = ::vesting::vesting_tests::ENotImplemented)]
    // fun test_vesting_fail() {
    //     abort ENotImplemented
    // }
}
