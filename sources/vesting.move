module vesting::vesting {
    use std::ascii;
    use std::option::{none};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, CoinMetadata, TreasuryCap};
    use sui::clock::{Self, Clock};
    use suilend::decimal;

    const EEndTimeBeforeStartTime: u64 = 0;
    const ERedeemingBeforeStartTime: u64 = 1;
    const ENotEnoughPenaltyFunds: u64 = 2;
    const EIncorrectAdminCap: u64 = 3;

    public struct VestingManager<phantom Ticket, phantom Vesting, phantom Penalty> has key {
        id: UID,
        vesting_balance: Balance<Vesting>,
        penalty_balance: Balance<Penalty>,
        ticket_treasury_cap: TreasuryCap<Ticket>,
        start_penalty_numerator: u64,
        end_penalty_numerator: u64,
        penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
    }

    public struct AdminCap<phantom Ticket, phantom Vesting, phantom Penalty> has key, store {
        id: UID,
        manager: ID,
    }

    public fun mint_tickets<Ticket: drop, Vesting, Penalty>(
        otw: Ticket,
        vesting_coin: Coin<Vesting>,
        coin_meta: &CoinMetadata<Vesting>,
        start_penalty_numerator: u64,
        end_penalty_numerator: u64,
        penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
        ctx: &mut TxContext,
    ): (AdminCap<Ticket, Vesting, Penalty>, VestingManager<Ticket, Vesting, Penalty>, Coin<Ticket>) {
        assert!(end_time_s > start_time_s, EEndTimeBeforeStartTime);
        
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
            ticket_treasury_cap: treasury_cap,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
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
    
    public fun redeem_ticket<Ticket, Vesting, Penalty>(
        manager: &mut VestingManager<Ticket, Vesting, Penalty>,
        ticket_coin: Coin<Ticket>,
        penalty_coin: &mut Coin<Penalty>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<Vesting> {
        let withdraw_amount = ticket_coin.value();
        let current_time = clock::timestamp_ms(clock) / 1000;
    
        // Ensure current time is within the valid range
        assert!(current_time >= manager.start_time_s, ERedeemingBeforeStartTime);

        // Interpolate penalty linearly
        let end_penalty = decimal::from(manager.end_penalty_numerator)
                .mul(decimal::from(withdraw_amount))
                .div(decimal::from(manager.penalty_denominator));

        let penalty_amount = if (current_time < manager.end_time_s) {
            let start_penalty = decimal::from(manager.start_penalty_numerator)
                .mul(decimal::from(withdraw_amount))
                .div(decimal::from(manager.penalty_denominator));

            let time_weight = decimal::from(manager.end_time_s)
                .sub(decimal::from(current_time))
                .div(decimal::from(manager.end_time_s).sub(decimal::from(manager.start_time_s)));
            
            start_penalty.mul(time_weight).add(end_penalty.mul(decimal::from(1).sub(time_weight))).ceil()
        } else { end_penalty.ceil() };

        assert!(penalty_coin.value() >= penalty_amount, ENotEnoughPenaltyFunds);

        // Consume used ticket coin
        manager.ticket_treasury_cap.burn(ticket_coin);

        manager.penalty_balance.join(
            penalty_coin.balance_mut().split(penalty_amount)
        );

        // Return vested coin
        coin::from_balance(manager.vesting_balance.split(withdraw_amount), ctx)
    }

    public fun collect_penalties<Ticket, Vesting, Penalty>(
        manager: &mut VestingManager<Ticket, Vesting, Penalty>,
        admin_cap: &AdminCap<Ticket, Vesting, Penalty>,
        ctx: &mut TxContext,
    ): Coin<Penalty> {
        assert!(admin_cap.manager == object::id(manager), EIncorrectAdminCap);
        coin::from_balance(manager.penalty_balance.withdraw_all(), ctx)
    }

    // View functions
    public fun manager<Ticket, Vesting, Penalty>(admin_cap: &AdminCap<Ticket, Vesting, Penalty>): ID { admin_cap.id.to_inner() }
    public fun start_penalty_numerator<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.start_penalty_numerator }
    public fun end_penalty_numerator<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.end_penalty_numerator }
    public fun penalty_denominator<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.penalty_denominator }
    public fun start_time_s<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.start_time_s }
    public fun end_time_s<Ticket, Vesting, Penalty>(manager: &VestingManager<Ticket, Vesting, Penalty>): u64 { manager.end_time_s }
}