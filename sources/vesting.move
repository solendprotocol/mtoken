module vesting::vesting {
    use std::ascii;
    use std::option::{none};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, CoinMetadata, TreasuryCap};
    use sui::clock::{Self, Clock};
    // use vesting::decimal::{from as decimal};

    public struct VestingManager<phantom W, phantom T, phantom P> has key {
        id: UID,
        underlying_balance: Balance<T>,
        penalty_balance: Balance<P>,
        treasury_cap: TreasuryCap<W>,
        start_penalty_numerator: u64,
        start_penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
    }

    public struct AdminCap<phantom W, phantom T, phantom P> has key, store {
        id: UID,
        manager: ID,
    }

    public fun mint_vesting_coin<W: drop, T, P>(
        otw: W,
        underlying_coin: Coin<T>,
        coin_meta: &CoinMetadata<T>,
        start_penalty_numerator: u64,
        start_penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
        ctx: &mut TxContext,
    ): (AdminCap<W, T, P>, VestingManager<W, T, P>, Coin<W>) {
        let mut name_ticker = ascii::string(b"WANG_"); // TODO
        name_ticker.append(coin_meta.get_symbol());

        let mut description = ascii::string(b"WANG Coin for ");  // TODO
        description.append(coin_meta.get_symbol());

        let (mut treasury_cap, metadata) = coin::create_currency(
            otw,
            coin_meta.get_decimals(),
            name_ticker.into_bytes(),
            name_ticker.into_bytes(),
            description.into_bytes(),
            none(), // TODO
            ctx,
        );

        let vesting_coin = treasury_cap.mint(underlying_coin.value(), ctx);

        let manager = VestingManager {
            id: object::new(ctx),
            underlying_balance: underlying_coin.into_balance(),
            penalty_balance: balance::zero(),
            treasury_cap,
            start_penalty_numerator,
            start_penalty_denominator,
            start_time_s,
            end_time_s,
        };
        
        let admin_cap = AdminCap {
            id: object::new(ctx),
            manager: manager.id.to_inner(),
        };

        transfer::public_freeze_object(metadata);

        (admin_cap, manager, vesting_coin)
    }

    
    public fun redeem<W, T, P>(
        manager: &mut VestingManager<W, T, P>,
        vesting_coin: Coin<W>,
        penalty_coin: &mut Coin<P>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<T> {
        let withdraw_amount = vesting_coin.value();
        let current_time = clock::timestamp_ms(clock) / 1000;
    
        // Ensure current time is within the valid range
        assert!(current_time >= manager.start_time_s, 1);
        assert!(withdraw_amount <= manager.underlying_balance.value(), 0);

        // Interpolate penalty linearly
        let penalty_amount = if (current_time < manager.end_time_s) {
            let start_penalty = manager.start_penalty_numerator * withdraw_amount / manager.start_penalty_denominator;
            let current_penalty = start_penalty - (start_penalty * (current_time - manager.start_time_s) / (manager.end_time_s - manager.start_time_s));

            current_penalty
        } else {0};

        // Apply the penalty
        assert!(penalty_coin.value() >= penalty_amount, 3);

        // Consume used vesting coin
        manager.treasury_cap.burn(vesting_coin);

        manager.penalty_balance.join(
            penalty_coin.balance_mut().split(penalty_amount)
        );

        // Return underlying coin
        coin::from_balance(manager.underlying_balance.split(withdraw_amount), ctx)
    }

    public fun collect_penalties<W, T, P>(
        admin_cap: &AdminCap<W, T, P>,
        manager: &mut VestingManager<W, T, P>,
        ctx: &mut TxContext,
    ): Coin<P> {
        assert!(admin_cap.manager == object::id(manager), 0);
        coin::from_balance(manager.penalty_balance.withdraw_all(), ctx)
    }

    // View functions
    public fun manager<W, T, P>(admin_cap: &AdminCap<W, T, P>): ID { admin_cap.id.to_inner() }
    public fun start_penalty_numerator<W, T, P>(manager: &VestingManager<W, T, P>): u64 { manager.start_penalty_numerator }
    public fun start_penalty_denominator<W, T, P>(manager: &VestingManager<W, T, P>): u64 { manager.start_penalty_denominator }
    public fun start_time_s<W, T, P>(manager: &VestingManager<W, T, P>): u64 { manager.start_time_s }
    public fun end_time_s<W, T, P>(manager: &VestingManager<W, T, P>): u64 { manager.end_time_s }
}