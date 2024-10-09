// Comments:
// - Coin can't have wrapper type as CoinType
// - Having a Coin for the vesting and withdraw capability seems odd, cause you can exchange one without the other
module vesting::vesting {
    use std::debug::print;
    use std::ascii;
    use std::type_name::{get, TypeName};
    use std::option::{none};
    use sui::bag::{Self, Bag};
    use sui::vec_set::{Self, VecSet};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, CoinMetadata, TreasuryCap};
    use sui::clock::{Self, Clock};
    use vesting::decimal::{from as decimal};

    public struct TreasuryCapKey<phantom W, phantom T> has store, copy, drop {}
    public struct CoinVestingKey<phantom W, phantom T> has store, copy, drop {}
    public struct CoinPenaltyKey<phantom W, phantom P> has store, copy, drop {}

    public struct TreasuryManager has key {
        id: UID,
        // For easy off-chain readability
        coin_penalty_types: VecSet<TypeName>,
        fields: Bag,
    }

    public struct AdminCap has key, store {
        id: UID,
        manager: ID,
    }

    public struct PenaltyCap<phantom W, phantom T, phantom P> has key, store {
        id: UID,
        amount: u64,
        start_penalty: u64,
        start_time_s: u64,
        end_time_s: u64,
    }

    fun init(ctx: &mut TxContext) {
        let treasury_manager = TreasuryManager {
            id: object::new(ctx),
            coin_penalty_types: vec_set::empty(),
            fields: bag::new(ctx)
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
            manager: treasury_manager.id.to_inner(),
        };

        transfer::public_transfer(admin_cap, ctx.sender());
        transfer::share_object(treasury_manager);
    }

    public fun create_vesting_coin<W: drop, T>(
        otw: W,
        manager: &mut TreasuryManager,
        coin_meta: &CoinMetadata<T>,
        ctx: &mut TxContext,
    ) {
        let mut name_ticker = ascii::string(b"WANG_"); // TODO
        name_ticker.append(coin_meta.get_symbol());

        let mut description = ascii::string(b"WANG Coin for ");  // TODO
        description.append(coin_meta.get_symbol());

        let (treasury_cap, metadata) = coin::create_currency(
            otw,
            coin_meta.get_decimals(),
            name_ticker.into_bytes(),
            name_ticker.into_bytes(),
            description.into_bytes(),
            none(), // TODO
            ctx,
        );

        manager.fields.add(TreasuryCapKey<W, T> {},treasury_cap);
        transfer::public_freeze_object(metadata);
    }
    
    public fun mint_vesting_coin<W, T, P>(
        manager: &mut TreasuryManager,
        start_penalty: u64,
        start_time_s: u64,
        end_time_s: u64,
        vesting_coins: Coin<T>,
        ctx: &mut TxContext,
    ): (Coin<W>, PenaltyCap<W, T, P>) {
        let coin_amount = vesting_coins.value();
        
        let penalty_cap = PenaltyCap {
            id: object::new(ctx),
            amount: coin_amount,
            start_penalty,
            start_time_s,
            end_time_s,
        };

        if (!manager.fields.contains(CoinVestingKey<W, T> {})) {
            manager.fields.add(CoinVestingKey<W, T> {}, balance::zero<T>())
        };

        if (!manager.coin_penalty_types.contains(&get<P>())) {
            manager.coin_penalty_types.insert(get<P>())
        };

        let treasury_balance: &mut Balance<T> = manager.fields.borrow_mut(CoinVestingKey<W, T> {});
        treasury_balance.join(vesting_coins.into_balance());

        let treasury: &mut TreasuryCap<W> = manager.fields.borrow_mut(TreasuryCapKey<W, T> {});

        (treasury.mint(coin_amount, ctx), penalty_cap)
    }
    
    public fun redeem<W, T, P>(
        manager: &mut TreasuryManager,
        ticket_coin: &mut Coin<W>,
        penalty_coin: &mut Coin<P>,
        penalty_cap: &mut PenaltyCap<W, T, P>,
        withdraw_amount: u64,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<T> {
        assert!(ticket_coin.value() >= withdraw_amount, 0);
        assert!(penalty_cap.amount >= withdraw_amount, 0);

        let current_time = clock::timestamp_ms(clock) / 1000;
    
        // Ensure current time is within the valid range
        assert!(current_time >= penalty_cap.start_time_s, 1);

        // Interpolate penalty linearly
        let penalty_amount = if (current_time < penalty_cap.end_time_s) {
            let start_penalty = decimal(penalty_cap.start_penalty).mul(decimal(withdraw_amount)).div(decimal(penalty_cap.amount));
            let time_weight = decimal(current_time).sub(decimal(penalty_cap.start_time_s)).div(
                decimal(penalty_cap.end_time_s).sub(decimal(penalty_cap.start_time_s))
            );
            let current_penalty = start_penalty.sub(
                start_penalty.mul(time_weight)
            ).ceil();
            
            // let current_penalty = start_penalty - (
            //     (start_penalty * (current_time - penalty_cap.start_time_s)) / (penalty_cap.end_time_s - penalty_cap.start_time_s)
            // );

            current_penalty
        } else {0};

        // Apply the penalty
        assert!(ticket_coin.value() >= withdraw_amount, 3);
        assert!(penalty_coin.value() >= penalty_amount, 3);

        // Update the penalty cap
        // Start penalty is scaled down depending of how much has been redeemed
        penalty_cap.start_penalty = penalty_cap.start_penalty * (penalty_cap.amount - withdraw_amount) / penalty_cap.amount;
        penalty_cap.amount = penalty_cap.amount - withdraw_amount;

        // Consume ticket coins
        let treasury: &mut TreasuryCap<W> = manager.fields.borrow_mut(TreasuryCapKey<W, T> {});

        // Consume used ticket amount
        treasury.burn(
            ticket_coin.split(withdraw_amount, ctx)
        );

        if (!manager.fields.contains(CoinPenaltyKey<W, P> {})) {
            manager.fields.add(CoinPenaltyKey<W, P> {}, balance::zero<P>())
        };

        let penalty_balance: &mut Balance<P> = manager.fields.borrow_mut(CoinPenaltyKey<W, P> {});

        penalty_balance.join(
            penalty_coin.balance_mut().split(penalty_amount)
        );

        // Return vested coin
        let coin_balance: &mut Balance<T> = manager.fields.borrow_mut(CoinVestingKey<W, T> {});


        coin::from_balance(coin_balance.split(withdraw_amount), ctx)
    }

    public fun collect_penalties<W, P>(
        _: &AdminCap,
        manager: &mut TreasuryManager,
        ctx: &mut TxContext,
    ): Coin<P> {

        let penalty_balance: &mut Balance<P> = manager.fields.borrow_mut(CoinPenaltyKey<W, P> {});

        coin::from_balance(penalty_balance.withdraw_all(), ctx)
    }

    #[allow(lint(self_transfer))]
    public fun try_destroy_empty<W, T, P>(
        penalty_cap: PenaltyCap<W, T, P>,
        ctx: &mut TxContext,
    ) {
        if (penalty_cap.amount == 0) {
            let PenaltyCap {
                id,
                amount: _,
                start_penalty: _,
                start_time_s: _,
                end_time_s: _,
            } = penalty_cap;

            object::delete(id);
        } else {
            transfer::public_transfer(penalty_cap, ctx.sender());
        };
    }

    // View functions

    public fun coin_penalty_types(manager: &TreasuryManager): &VecSet<TypeName> { &manager.coin_penalty_types }
    public fun fields(manager: &TreasuryManager): &Bag { &manager.fields }
    public fun manager(admin_cap: &AdminCap): ID { admin_cap.id.to_inner() }
    public fun amount<W, T, P>(penalty_cap: &PenaltyCap<W, T, P>): u64 { penalty_cap.amount }
    public fun start_penalty<W, T, P>(penalty_cap: &PenaltyCap<W, T, P>): u64 { penalty_cap.start_penalty }
    public fun start_time_s<W, T, P>(penalty_cap: &PenaltyCap<W, T, P>): u64 { penalty_cap.start_time_s }
    public fun end_time_s<W, T, P>(penalty_cap: &PenaltyCap<W, T, P>): u64 { penalty_cap.end_time_s }

    // Test functions

    #[test_only]
    public(package) fun init_for_testing(ctx: &mut TxContext): (TreasuryManager, AdminCap) {
        let treasury_manager = TreasuryManager {
            id: object::new(ctx),
            coin_penalty_types: vec_set::empty(),
            fields: bag::new(ctx)
        };

        let admin_cap = AdminCap {
            id: object::new(ctx),
            manager: treasury_manager.id.to_inner(),
        };

        (treasury_manager, admin_cap)
    }

    public(package) fun treasury_key_for_testing<W, T>(): TreasuryCapKey<W, T> { TreasuryCapKey {} }
    public(package) fun coin_vesting_key_for_testing<W, P>(): CoinVestingKey<W, P> { CoinVestingKey {} }
    public(package) fun coin_penalty_key_for_testing<W, P>(): CoinPenaltyKey<W, P> { CoinPenaltyKey {} }
}