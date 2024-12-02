module mtoken::mtoken {
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::clock::{Self, Clock};
    use suilend::decimal;
    use sui::url::{Url};

    const EEndTimeBeforeStartTime: u64 = 0;
    const ERedeemingBeforeStartTime: u64 = 1;
    const ENotEnoughPenaltyFunds: u64 = 2;
    const EIncorrectAdminCap: u64 = 3;

    public struct VestingManager<phantom MToken, phantom Vesting, phantom Penalty> has key, store {
        id: UID,
        vesting_balance: Balance<Vesting>,
        penalty_balance: Balance<Penalty>,
        mtoken_treasury_cap: TreasuryCap<MToken>,
        start_penalty_numerator: u64,
        end_penalty_numerator: u64,
        penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
    }

    public struct AdminCap<phantom MToken, phantom Vesting, phantom Penalty> has key, store {
        id: UID,
        manager: ID,
    }

    public fun init_manager<MToken: drop, Vesting, Penalty>(
        otw: MToken,
        decimals: u8,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: Option<Url>,
        start_penalty_numerator: u64,
        end_penalty_numerator: u64,
        penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
        ctx: &mut TxContext,
    ): (AdminCap<MToken, Vesting, Penalty>, VestingManager<MToken, Vesting, Penalty>) {
        assert!(end_time_s > start_time_s, EEndTimeBeforeStartTime);

        let (treasury_cap, metadata) = coin::create_currency(
            otw,
            decimals,
            symbol,
            name,
            description,
            icon_url,
            ctx,
        );

        let manager = VestingManager {
            id: object::new(ctx),
            vesting_balance: balance::zero(),
            penalty_balance: balance::zero(),
            mtoken_treasury_cap: treasury_cap,
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

        (admin_cap, manager)
    }
    
    public fun mint_mtokens<MToken: drop, Vesting, Penalty>(
        _admin: &AdminCap<MToken, Vesting, Penalty>,
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
        vesting_coin: Coin<Vesting>,
        ctx: &mut TxContext,
    ): Coin<MToken> {
        let vesting_coin_value = vesting_coin.value();
        
        manager.vesting_balance.join(vesting_coin.into_balance());
        manager.mtoken_treasury_cap.mint(vesting_coin_value, ctx)
    }
    
    public fun redeem_mtokens<MToken, Vesting, Penalty>(
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
        mtoken_coin: Coin<MToken>,
        penalty_coin: &mut Coin<Penalty>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<Vesting> {
        let withdraw_amount = mtoken_coin.value();
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

        // Consume used mtoken coin
        manager.mtoken_treasury_cap.burn(mtoken_coin);

        manager.penalty_balance.join(
            penalty_coin.balance_mut().split(penalty_amount)
        );

        // Return vested coin
        coin::from_balance(manager.vesting_balance.split(withdraw_amount), ctx)
    }

    public fun collect_penalties<MToken, Vesting, Penalty>(
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
        admin_cap: &AdminCap<MToken, Vesting, Penalty>,
        ctx: &mut TxContext,
    ): Coin<Penalty> {
        assert!(admin_cap.manager == object::id(manager), EIncorrectAdminCap);
        coin::from_balance(manager.penalty_balance.withdraw_all(), ctx)
    }

    // View functions
    public fun manager<MToken, Vesting, Penalty>(admin_cap: &AdminCap<MToken, Vesting, Penalty>): ID { admin_cap.id.to_inner() }
    public fun start_penalty_numerator<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.start_penalty_numerator }
    public fun end_penalty_numerator<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.end_penalty_numerator }
    public fun penalty_denominator<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.penalty_denominator }
    public fun start_time_s<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.start_time_s }
    public fun end_time_s<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.end_time_s }
}