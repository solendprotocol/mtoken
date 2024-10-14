module vesting::vesting {
    use std::ascii;
    use std::option::{none};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, CoinMetadata, TreasuryCap};
    use sui::clock::{Self, Clock};

    public struct VestingManager<phantom Ticket, phantom Vesting, phantom Penalty> has key {
        id: UID,
        vesting_balance: Balance<Vesting>,
        penalty_balance: Balance<Penalty>,
        treasury_cap: TreasuryCap<Ticket>,
        start_penalty_numerator: u64,
        start_penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
    }

    public struct AdminCap<phantom W, phantom T, phantom P> has key, store {
        id: UID,
        manager: ID,
    }

    public fun mint_tickets<Ticket: drop, Vesting, Penalty>(
        otw: Ticket,
        vesting_coin: Coin<Vesting>,
        coin_meta: &CoinMetadata<Vesting>,
        start_penalty_numerator: u64,
        start_penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
        ctx: &mut TxContext,
    ): (AdminCap<Ticket, Vesting, Penalty>, VestingManager<Ticket, Vesting, Penalty>, Coin<Ticket>) {
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

        let ticket_coin = treasury_cap.mint(vesting_coin.value(), ctx);

        let manager = VestingManager {
            id: object::new(ctx),
            vesting_balance: vesting_coin.into_balance(),
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

        (admin_cap, manager, ticket_coin)
    }

    
    public fun redeem<Ticket, Vesting, Penalty>(
        manager: &mut VestingManager<Ticket, Vesting, Penalty>,
        ticket_coin: Coin<Ticket>,
        penalty_coin: &mut Coin<Penalty>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<Vesting> {
        let withdraw_amount = ticket_coin.value();
        let current_time = clock::timestamp_ms(clock) / 1000;
    
        // Ensure current time is within the valid range
        assert!(current_time >= manager.start_time_s, 1);
        assert!(withdraw_amount <= manager.vesting_balance.value(), 0);

        // Interpolate penalty linearly
        let penalty_amount = if (current_time < manager.end_time_s) {
            let start_penalty = manager.start_penalty_numerator * withdraw_amount / manager.start_penalty_denominator;
            let current_penalty = start_penalty - (start_penalty * (current_time - manager.start_time_s) / (manager.end_time_s - manager.start_time_s));

            current_penalty
        } else {0};

        // Apply the penalty
        assert!(penalty_coin.value() >= penalty_amount, 3);

        // Consume used vesting coin
        manager.treasury_cap.burn(ticket_coin);

        manager.penalty_balance.join(
            penalty_coin.balance_mut().split(penalty_amount)
        );

        // Return vesting coin
        coin::from_balance(manager.vesting_balance.split(withdraw_amount), ctx)
    }

    public fun collect_penalties<Ticket, Vesting, Penalty>(
        admin_cap: &AdminCap<Ticket, Vesting, Penalty>,
        manager: &mut VestingManager<Ticket, Vesting, Penalty>,
        ctx: &mut TxContext,
    ): Coin<Penalty> {
        assert!(admin_cap.manager == object::id(manager), 0);
        coin::from_balance(manager.penalty_balance.withdraw_all(), ctx)
    }

    // View functions
    public fun manager<Ticket, Vesting, Penalty>(admin_cap: &AdminCap<Ticket, Vesting, Penalty>): ID { admin_cap.id.to_inner() }
    public fun start_penalty_numerator<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.start_penalty_numerator }
    public fun start_penalty_denominator<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.start_penalty_denominator }
    public fun start_time_s<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.start_time_s }
    public fun end_time_s<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.end_time_s }
}