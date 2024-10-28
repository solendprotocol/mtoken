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
        
        let (admin_cap, manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
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

    #[test]
    #[expected_failure(abort_code = vesting::EEndTimeBeforeStartTime)]
    fun test_fail_end_time_before_start_time() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        destroy(vesting_coin);
        destroy(clock);
        destroy(metadata);
        destroy(treasury_cap);
        destroy(manager);
        destroy(admin_cap);

        test_scenario::end(scenario);
    }
    
    #[test]
    #[expected_failure(abort_code = vesting::ERedeemingBeforeStartTime)]
    fun test_fail_redeem_before_start_time() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));
        clock.set_for_testing(1000);

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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
    #[expected_failure(abort_code = vesting::ENotEnoughPenaltyFunds)]
    fun test_fail_not_enough_penalty_funds() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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
    #[expected_failure(abort_code = vesting::EIncorrectAdminCap)]
    fun test_fail_collect_wrong_admin_cap() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (fake_admin_cap, fake_manager, fake_vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
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
        destroy(fake_vesting_coin);

        test_scenario::end(scenario);
    }

    #[test]
    fun test_immediate_redeem_with_end_price() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
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
    fun test_mid_time_redeem_with_end_price() {
        let owner = @0x10;
        let mut scenario = test_scenario::begin(owner);
        let mut clock = clock::create_for_testing(ctx(&mut scenario));

        let (mut treasury_cap, metadata) = underlying::create_currency(ctx(&mut scenario));
        let underlying_coin = treasury_cap.mint(8_000, ctx(&mut scenario));

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
            &mut manager,
            vesting_coin,
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

        let (admin_cap, mut manager, vesting_coin) = vesting::mint_tickets<VEST, UNDERLYING, SUI>(
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

        let unvested_coin = vesting::redeem_ticket<VEST, UNDERLYING, SUI>(
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
}
