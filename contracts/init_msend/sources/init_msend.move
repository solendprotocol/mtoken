#[allow(lint(share_owned, self_transfer))]
module init_msend::init_msend {
    use mtoken::mtoken::{Self, AdminCap, VestingManager};
    use sui::coin::{Coin, TreasuryCap};
    use sui::sui::SUI;
    use send::send::SEND;
    use msend_series_1::msend_series_1::MSEND_SERIES_1;
    use msend_series_2::msend_series_2::MSEND_SERIES_2;
    use msend_series_3::msend_series_3::MSEND_SERIES_3;

    const START_TIME_S: u64 = 1733979600;

    const MSEND_SERIES_1_AMOUNT: u64 = 25_000_000 * 1_000_000;
    const MSEND_SERIES_2_AMOUNT: u64 = 6_875_000 * 1_000_000;
    const MSEND_SERIES_3_AMOUNT: u64 = 15_000_000 * 1_000_000;

    entry fun init_msend(
        msend_series_1_treasury_cap: TreasuryCap<MSEND_SERIES_1>,
        msend_series_2_treasury_cap: TreasuryCap<MSEND_SERIES_2>,
        msend_series_3_treasury_cap: TreasuryCap<MSEND_SERIES_3>,
        send: &mut Coin<SEND>,
        ctx: &mut TxContext,
    ) {
        // mSEND 3 month
        let (admin_cap, manager, mtoken_coin) = mint_msend3(
            msend_series_1_treasury_cap,
            send.split(MSEND_SERIES_1_AMOUNT, ctx),
            ctx,
        );

        transfer::public_transfer(admin_cap, ctx.sender());
        transfer::public_transfer(mtoken_coin, ctx.sender());
        transfer::public_share_object(manager);

        // mSEND 6 month
        let (admin_cap, manager, mtoken_coin) = mint_msend6(
            msend_series_2_treasury_cap,
            send.split(MSEND_SERIES_2_AMOUNT, ctx),
            ctx,
        );

        transfer::public_transfer(admin_cap, ctx.sender());
        transfer::public_transfer(mtoken_coin, ctx.sender());
        transfer::public_share_object(manager);

        // mSEND 12 month
        let (admin_cap, manager, mtoken_coin) = mint_msend12(
            msend_series_3_treasury_cap,
            send.split(MSEND_SERIES_3_AMOUNT, ctx),
            ctx,
        );

        transfer::public_transfer(admin_cap, ctx.sender());
        transfer::public_transfer(mtoken_coin, ctx.sender());
        transfer::public_share_object(manager);
    }
    
    public(package) fun mint_msend3(
        msend_series_1_treasury_cap: TreasuryCap<MSEND_SERIES_1>,
        send_for_3_month: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_SERIES_1, SEND, SUI>, VestingManager<MSEND_SERIES_1, SEND, SUI>, Coin<MSEND_SERIES_1>) {
        // mSEND 3 month
        let start_penalty_numerator = 250; // 0.25*10^(9-6) = 1_000 / 4 = 1 * 10^3 / 4
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;
        let end_time_s = 1741752000;

        mtoken::mint_mtokens<MSEND_SERIES_1, SEND, SUI>(
            msend_series_1_treasury_cap,
            send_for_3_month,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            START_TIME_S,
            end_time_s,
            ctx,
        )
    }
    
    public(package) fun mint_msend6(
        msend_series_2_treasury_cap: TreasuryCap<MSEND_SERIES_2>,
        send_for_6_month: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_SERIES_2, SEND, SUI>, VestingManager<MSEND_SERIES_2, SEND, SUI>, Coin<MSEND_SERIES_2>) {
        // mSEND 6 month
        let start_penalty_numerator = 500;
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;
        let end_time_s = 1749700800;

        mtoken::mint_mtokens<MSEND_SERIES_2, SEND, SUI>(
            msend_series_2_treasury_cap,
            send_for_6_month,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            START_TIME_S,
            end_time_s,
            ctx,
        )
    }
    
    public(package) fun mint_msend12(
        msend_series_3_treasury_cap: TreasuryCap<MSEND_SERIES_3>,
        send_for_12_month: Coin<SEND>,
        ctx: &mut TxContext,
    ): (AdminCap<MSEND_SERIES_3, SEND, SUI>, VestingManager<MSEND_SERIES_3, SEND, SUI>, Coin<MSEND_SERIES_3>) {
        // mSEND 12 month

        let start_penalty_numerator = 375;
        let end_penalty_numerator = 0;
        let penalty_denominator = 1;
        let end_time_s = 1765515600;

        mtoken::mint_mtokens<MSEND_SERIES_3, SEND, SUI>(
            msend_series_3_treasury_cap,
            send_for_12_month,
            start_penalty_numerator,
            end_penalty_numerator,
            penalty_denominator,
            START_TIME_S,
            end_time_s,
            ctx,
        )
    }
}
