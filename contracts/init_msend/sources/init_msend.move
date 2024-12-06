#[allow(lint(share_owned, self_transfer))]
module init_msend::init_msend {
    use mtoken::mtoken::{Self, AdminCap, VestingManager};
    use sui::coin::{Coin, TreasuryCap};
    use sui::sui::SUI;
    use send::send::SEND;
    use msend_3_month::msend_3_month::MSEND_3_MONTH;
    use msend_6_month::msend_6_month::MSEND_6_MONTH;
    use msend_12_month::msend_12_month::MSEND_12_MONTH;

    public fun init_msend(
        msend_3_month_treasury_cap: TreasuryCap<MSEND_3_MONTH>,
        msend_6_month_treasury_cap: TreasuryCap<MSEND_6_MONTH>,
        msend_12_month_treasury_cap: TreasuryCap<MSEND_12_MONTH>,
        send_for_3_month: Coin<SEND>,
        send_for_6_month: Coin<SEND>,
        send_for_12_month: Coin<SEND>,
        ctx: &mut TxContext,
    ) {
        // mSEND 3 month
        let (admin_cap, manager, mtoken_coin) = mint_msend3(
            msend_3_month_treasury_cap,
            send_for_3_month,
            ctx,
        );

        transfer::public_transfer(admin_cap, ctx.sender());
        transfer::public_transfer(mtoken_coin, ctx.sender());
        transfer::public_share_object(manager);

        // mSEND 6 month
        let (admin_cap, manager, mtoken_coin) = mint_msend6(
            msend_6_month_treasury_cap,
            send_for_6_month,
            ctx,
        );

        transfer::public_transfer(admin_cap, ctx.sender());
        transfer::public_transfer(mtoken_coin, ctx.sender());
        transfer::public_share_object(manager);

        // mSEND 12 month
        let (admin_cap, manager, mtoken_coin) = mint_msend12(
            msend_12_month_treasury_cap,
            send_for_12_month,
            ctx,
        );

        transfer::public_transfer(admin_cap, ctx.sender());
        transfer::public_transfer(mtoken_coin, ctx.sender());
        transfer::public_share_object(manager);
    }
    
    public(package) fun mint_msend3(
        msend_3_month_treasury_cap: TreasuryCap<MSEND_3_MONTH>,
        send_for_3_month: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_3_MONTH, SEND, SUI>, VestingManager<MSEND_3_MONTH, SEND, SUI>, Coin<MSEND_3_MONTH>) {
        // mSEND 3 month
        let start_penalty_numerator = 250; // 0.25*10^(9-6) = 1_000 / 4 = 1 * 10^3 / 4
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;
        let start_time_ts = 1733508512;
        let end_time_ts = 1741802912;

        mtoken::mint_mtokens<MSEND_3_MONTH, SEND, SUI>(
            msend_3_month_treasury_cap,
            send_for_3_month,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            start_time_ts,
            end_time_ts,
            ctx,
        )
    }
    
    public(package) fun mint_msend6(
        msend_6_month_treasury_cap: TreasuryCap<MSEND_6_MONTH>,
        send_for_6_month: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_6_MONTH, SEND, SUI>, VestingManager<MSEND_6_MONTH, SEND, SUI>, Coin<MSEND_6_MONTH>) {
        // mSEND 6 month
        let start_penalty_numerator = 500;
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;
        let start_time_ts = 1733508512;
        let end_time_ts = 1749748112;

        mtoken::mint_mtokens<MSEND_6_MONTH, SEND, SUI>(
            msend_6_month_treasury_cap,
            send_for_6_month,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            start_time_ts,
            end_time_ts,
            ctx,
        )
    }
    
    public(package) fun mint_msend12(
        msend_12_month_treasury_cap: TreasuryCap<MSEND_12_MONTH>,
        send_for_12_month: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_12_MONTH, SEND, SUI>, VestingManager<MSEND_12_MONTH, SEND, SUI>, Coin<MSEND_12_MONTH>) {
        // mSEND 12 month

        let start_penalty_numerator = 375;
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;
        let start_time_ts = 1733508512;
        let end_time_ts = 1749748112;

        mtoken::mint_mtokens<MSEND_12_MONTH, SEND, SUI>(
            msend_12_month_treasury_cap,
            send_for_12_month,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            start_time_ts,
            end_time_ts,
            ctx,
        )
    }
}
