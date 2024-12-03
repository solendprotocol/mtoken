module send::msend {
    use mtoken::mtoken;
    use send::send::SEND;
    use sui::sui::SUI;

    const START_TIME_S: u64 = 1733228602;
    const END_TIME_S: u64 = 1734006202;

    public struct MSEND has drop {}

    fun init(otw: MSEND, ctx: &mut TxContext) {
        let (admin_cap, manager) = mtoken::init_manager<MSEND, SEND, SUI>(
            otw, // otw
            6,  // decimals
            b"MSEND",  // symbol
            b"MSEND",  // name
            b"MSEND",  // description
            option::none(),  // icon_url
            10, // start_penalty_numerator
            1, // end_penalty_numerator
            100_000, // penalty_denominator
            START_TIME_S, // start_time_s
            END_TIME_S, // end_time_s
            ctx,
        );

        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_share_object(manager);
    }

    #[test_only]
    public(package) fun init_for_testing(ctx: &mut TxContext) {
        init(MSEND {}, ctx)
    }
}