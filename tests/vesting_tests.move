#[test_only]
module vesting::vesting_tests {
    use std::debug::print;
    use vesting::vesting;
    use vesting::vested_coin::{Self, VESTED_COIN};
    use vesting::option_coin::OPTION_COIN;
    use sui::coin::{Self, Coin, TreasuryCap, CoinMetadata};
    use sui::clock;
    use sui::sui::SUI;
    use sui::test_scenario::{Self, ctx};
    use sui::test_utils::{create_one_time_witness, destroy};

    #[test]
    fun test_init() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);

        let (manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_create_vesting_coin() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);

        let (mut manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

        let (treasury_cap, metadata) = vested_coin::create_currency(ctx(&mut scenario));

        vesting::create_vesting_coin(
            create_one_time_witness<OPTION_COIN>(),
            &mut manager,
            &metadata,
            ctx(&mut scenario),
        );

        scenario.next_tx(owner);

        let vesting_meta: CoinMetadata<OPTION_COIN> = scenario.take_immutable();

        assert!(
            manager.fields().contains(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        ), 0);

        let _treasury_cap: &TreasuryCap<OPTION_COIN> = manager.fields().borrow(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        );

        destroy(metadata);
        destroy(vesting_meta);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_mint_vesting_coin() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);

        let (mut manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = vested_coin::create_currency(ctx(&mut scenario));

        vesting::create_vesting_coin(
            create_one_time_witness<OPTION_COIN>(),
            &mut manager,
            &metadata,
            ctx(&mut scenario),
        );

        scenario.next_tx(owner);

        let vesting_meta: CoinMetadata<OPTION_COIN> = scenario.take_immutable();

        assert!(
            manager.fields().contains(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        ), 0);

        let _treasury_cap: &TreasuryCap<OPTION_COIN> = manager.fields().borrow(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        );

        let clock = clock::create_for_testing(ctx(&mut scenario));
        let coins_to_vest = treasury_cap.mint(10_000, ctx(&mut scenario));
        let current_time = clock.timestamp_ms() / 1_000;

        let (vested_coin, penalty_cap) = vesting::mint_vesting_coin<OPTION_COIN,VESTED_COIN, SUI>(
            &mut manager,
            1_000, // 10% in bps
            current_time, // start_time_s
            current_time + 100, // end_time_s
            coins_to_vest,
            ctx(&mut scenario),
        );

        assert!(penalty_cap.amount() == 10_000, 0);
        assert!(penalty_cap.start_penalty_bps() == 1_000, 0);
        assert!(penalty_cap.start_time_s() == current_time, 0);
        assert!(penalty_cap.end_time_s() == current_time + 100, 0);
        assert!(vested_coin.value() == 10_000, 0);

        destroy(clock);
        destroy(metadata);
        destroy(vested_coin);
        destroy(penalty_cap);
        destroy(vesting_meta);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_immediate_redeem() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);

        let (mut manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = vested_coin::create_currency(ctx(&mut scenario));

        vesting::create_vesting_coin(
            create_one_time_witness<OPTION_COIN>(),
            &mut manager,
            &metadata,
            ctx(&mut scenario),
        );

        scenario.next_tx(owner);

        let vesting_meta: CoinMetadata<OPTION_COIN> = scenario.take_immutable();

        assert!(
            manager.fields().contains(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        ), 0);

        let _treasury_cap: &TreasuryCap<OPTION_COIN> = manager.fields().borrow(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        );

        let clock = clock::create_for_testing(ctx(&mut scenario));
        let coins_to_vest = treasury_cap.mint(10_000, ctx(&mut scenario));

        let (mut vested_coin, mut penalty_cap) = vesting::mint_vesting_coin<OPTION_COIN,VESTED_COIN, SUI>(
            &mut manager,
            1_000,
            clock.timestamp_ms() / 1_000, // start_time_s
            (clock.timestamp_ms() / 1_000) + 100, // end_time_s
            coins_to_vest,
            ctx(&mut scenario),
        );

        // Immediate redeem
        let mut sui: Coin<SUI> = coin::mint_for_testing(5_000, ctx(&mut scenario));

        let withdraw_amount = vested_coin.value();
        let unvested_coin = vesting::redeem<OPTION_COIN,VESTED_COIN, SUI>(
            &mut manager,
            &mut vested_coin,
            &mut sui,
            &mut penalty_cap,
            withdraw_amount,
            &clock,
            ctx(&mut scenario),
        );

        assert!(unvested_coin.value() == withdraw_amount, 0);
        assert!(vested_coin.value() == 0, 0);
        assert!(sui.value() == 5_000 - withdraw_amount / 10, 0);
        assert!(penalty_cap.amount() == 0, 0);

        vesting::try_destroy_empty(penalty_cap, ctx(&mut scenario));

        destroy(unvested_coin);
        destroy(vested_coin);
        destroy(clock);
        destroy(sui);
        destroy(metadata);
        destroy(vesting_meta);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    fun test_redeem_at_maturity() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);

        let (mut manager, admin_cap) = vesting::init_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = vested_coin::create_currency(ctx(&mut scenario));

        vesting::create_vesting_coin(
            create_one_time_witness<OPTION_COIN>(),
            &mut manager,
            &metadata,
            ctx(&mut scenario),
        );

        scenario.next_tx(owner);

        let vesting_meta: CoinMetadata<OPTION_COIN> = scenario.take_immutable();

        assert!(
            manager.fields().contains(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        ), 0);

        let _treasury_cap: &TreasuryCap<OPTION_COIN> = manager.fields().borrow(
            vesting::treasury_key_for_testing<OPTION_COIN, VESTED_COIN>()
        );

        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        let coins_to_vest = treasury_cap.mint(10_000, ctx(&mut scenario));

        let (mut vested_coin, mut penalty_cap) = vesting::mint_vesting_coin<OPTION_COIN,VESTED_COIN, SUI>(
            &mut manager,
            1_000,
            clock.timestamp_ms() / 1_000, // start_time_s
            (clock.timestamp_ms() / 1_000) + 100, // end_time_s
            coins_to_vest,
            ctx(&mut scenario),
        );

        // Redeem at maturity
        let mut sui: Coin<SUI> = coin::mint_for_testing(5_000, ctx(&mut scenario));
        clock.increment_for_testing(100 * 1_000);

        let withdraw_amount = vested_coin.value();
        let unvested_coin = vesting::redeem<OPTION_COIN,VESTED_COIN, SUI>(
            &mut manager,
            &mut vested_coin,
            &mut sui,
            &mut penalty_cap,
            withdraw_amount,
            &clock,
            ctx(&mut scenario),
        );

        assert!(unvested_coin.value() == withdraw_amount, 0);
        assert!(vested_coin.value() == 0, 0);
        assert!(sui.value() == 5_000, 0);
        assert!(penalty_cap.amount() == 0, 0);

        vesting::try_destroy_empty(penalty_cap, ctx(&mut scenario));

        destroy(unvested_coin);
        destroy(vested_coin);
        destroy(clock);
        destroy(sui);
        destroy(metadata);
        destroy(vesting_meta);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }

    

    // #[test, expected_failure(abort_code = ::vesting::vesting_tests::ENotImplemented)]
    // fun test_vesting_fail() {
    //     abort ENotImplemented
    // }
}
