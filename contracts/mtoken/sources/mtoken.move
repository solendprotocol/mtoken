module mtoken::mtoken {
    use std::type_name::{Self, TypeName};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::clock::{Self, Clock};
    use sui::event::emit;
    use suilend::decimal;

    // ===== Constants =====

    const VERSION: u64 = 0;

    // ===== Errors =====

    const EIncorrectVersion: u64 = 999;
    const EEndTimeBeforeStartTime: u64 = 0;
    const ERedeemingBeforeStartTime: u64 = 1;
    const ENotEnoughPenaltyFunds: u64 = 2;
    const EIncorrectAdminCap: u64 = 3;
    const EMTokenSupplyNotZero: u64 = 4;

    // ===== Structs =====

    public struct VestingManager<phantom MToken, phantom Vesting, phantom Penalty> has key, store {
        id: UID,
        version: u64,
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

    // ===== Events =====

    public struct MintMTokensEvent has store, copy, drop {
        manager_id: ID,
        mtoken_minted: u64,
        mtoken_type: TypeName,
        vesting_type: TypeName,
        penalty_type: TypeName,
    }

    public struct RedeemMTokensEvent has store, copy, drop {
        manager_id: ID,
        withdraw_amount: u64,
        penalty_amount: u64,
        mtoken_type: TypeName,
        vesting_type: TypeName,
        penalty_type: TypeName,
    }

    public struct PenaltyCollectedEvent has store, copy, drop {
        manager_id: ID,
        amount_collected: u64,
        mtoken_type: TypeName,
        vesting_type: TypeName,
        penalty_type: TypeName,
    }

    // ===== Public functions =====

    public fun mint_mtokens<MToken: drop, Vesting, Penalty>(
        mut treasury_cap: TreasuryCap<MToken>,
        vesting_coin: Coin<Vesting>,
        start_penalty_numerator: u64,
        end_penalty_numerator: u64,
        penalty_denominator: u64,
        start_time_s: u64,
        end_time_s: u64,
        ctx: &mut TxContext,
    ): (AdminCap<MToken, Vesting, Penalty>, VestingManager<MToken, Vesting, Penalty>, Coin<MToken>) {
        assert!(end_time_s > start_time_s, EEndTimeBeforeStartTime);
        assert!(treasury_cap.supply().supply_value() == 0, EMTokenSupplyNotZero);

        let mut manager = VestingManager {
            id: object::new(ctx),
            version: VERSION,
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

        let mtoken_coin = mint_mtokens_internal(
            &mut manager,
            &admin_cap,
            vesting_coin,
            ctx,
        );

        (admin_cap, manager, mtoken_coin)
    }

    public fun mint_more_mtokens<MToken, Vesting, Penalty>(
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
        admin_cap: &AdminCap<MToken, Vesting, Penalty>,
        coin: Coin<Vesting>,
        ctx: &mut TxContext,
    ): Coin<MToken> {
        mint_mtokens_internal(manager, admin_cap, coin, ctx)
    }

    fun mint_mtokens_internal<MToken, Vesting, Penalty>(
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
        _: &AdminCap<MToken, Vesting, Penalty>,
        coin: Coin<Vesting>,
        ctx: &mut TxContext,
    ): Coin<MToken> {
        manager.assert_version_and_upgrade();

        let mtoken_coin = manager.mtoken_treasury_cap.mint(coin.value(), ctx);
        manager.vesting_balance.join(coin.into_balance());

        emit(MintMTokensEvent {
            manager_id: manager.id.to_inner(),
            mtoken_minted: mtoken_coin.value(),
            mtoken_type: type_name::get<MToken>(),
            vesting_type: type_name::get<Vesting>(),
            penalty_type: type_name::get<Penalty>(),
        });

        mtoken_coin
    }
    
    public fun redeem_mtokens<MToken, Vesting, Penalty>(
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
        mtoken_coin: Coin<MToken>,
        penalty_coin: &mut Coin<Penalty>,
        clock: &Clock,
        ctx: &mut TxContext,
    ): Coin<Vesting> {
        manager.assert_version_and_upgrade();

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

        emit(RedeemMTokensEvent {
            manager_id: manager.id.to_inner(),
            withdraw_amount,
            penalty_amount,
            mtoken_type: type_name::get<MToken>(),
            vesting_type: type_name::get<Vesting>(),
            penalty_type: type_name::get<Penalty>(),
        });

        // Return vested coin
        coin::from_balance(manager.vesting_balance.split(withdraw_amount), ctx)
    }

    public fun collect_penalties<MToken, Vesting, Penalty>(
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
        admin_cap: &AdminCap<MToken, Vesting, Penalty>,
        ctx: &mut TxContext,
    ): Coin<Penalty> {
        manager.assert_version_and_upgrade();
        assert!(admin_cap.manager == object::id(manager), EIncorrectAdminCap);

        let balance = manager.penalty_balance.withdraw_all();

        emit(PenaltyCollectedEvent {
            manager_id: manager.id.to_inner(),
            amount_collected: balance.value(),
            mtoken_type: type_name::get<MToken>(),
            vesting_type: type_name::get<Vesting>(),
            penalty_type: type_name::get<Penalty>(),
        });

        coin::from_balance(balance, ctx)
    }

    // ===== View functions =====

    public fun manager<MToken, Vesting, Penalty>(admin_cap: &AdminCap<MToken, Vesting, Penalty>): ID { admin_cap.id.to_inner() }
    public fun start_penalty_numerator<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.start_penalty_numerator }
    public fun end_penalty_numerator<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.end_penalty_numerator }
    public fun penalty_denominator<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.penalty_denominator }
    public fun start_time_s<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.start_time_s }
    public fun end_time_s<MToken, Vesting, Penalty>(manager: &VestingManager<MToken, Vesting, Penalty>): u64 { manager.end_time_s }

    // ===== Upgrade functions =====

    public fun migrate<MToken: drop, Vesting, Penalty>(
        _admin: &AdminCap<MToken, Vesting, Penalty>,
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
    ) {
        assert!(manager.version < VERSION, EIncorrectVersion);
        manager.version = VERSION;
    }

    // ===== Package functions =====

    public(package) fun assert_version<MToken, Vesting, Penalty>(
        manager: &VestingManager<MToken, Vesting, Penalty>,
    ) {
        assert!(manager.version == VERSION, EIncorrectVersion);
    }

    public(package) fun assert_version_and_upgrade<MToken, Vesting, Penalty>(
        manager: &mut VestingManager<MToken, Vesting, Penalty>,
    ) {
        if (manager.version < VERSION) {
            manager.version = VERSION;
        };
        assert_version(manager);
    }
}