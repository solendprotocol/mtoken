module send::msend {
    // use sui::url;
    use mtoken::mtoken;
    use send::send::SEND;
    use usdc::usdc::USDC;

    const START_TIME_S: u64 = 0; // TODO
    const END_TIME_S: u64 = 100; // TODO

    public struct MSEND has drop {}

    fun init(otw: MSEND, ctx: &mut TxContext) {
        let (admin_cap, manager) = mtoken::init_manager<MSEND, SEND, USDC>(
            otw, // otw
            6,  // decimals
            b"MSEND",  // symbol
            b"MSEND",  // name
            b"MSEND",  // description
            option::none(),  // icon_url
            10, // start_penalty_numerator
            0, // end_penalty_numerator
            100, // penalty_denominator
            START_TIME_S, // start_time_s
            END_TIME_S, // end_time_s
            ctx,
        );

        transfer::public_transfer(admin_cap, tx_context::sender(ctx));
        transfer::public_share_object(manager);
    }

    #[test_only]
    use mtoken::mtoken::{AdminCap, VestingManager};
    #[test_only]
    use sui::test_scenario;
    #[test_only]
    use sui::coin::Coin;
    #[test_only]
    use send::send;

    #[test]
    public fun mint_mtokens() {
        let mut scenario = test_scenario::begin(@0x10);

        send::init_for_testing(scenario.ctx());
        scenario.next_tx(@0x10);
        let send: Coin<SEND> = scenario.take_from_address(@0x10);

        init(MSEND {}, scenario.ctx());
        scenario.next_tx(@0x10);

        let admin_cap: AdminCap<MSEND, SEND, USDC> = scenario.take_from_address(@0x10);
        let mut manager: VestingManager<MSEND, SEND, USDC> = scenario.take_shared();

        let msend = admin_cap.mint_mtokens(&mut manager, send, scenario.ctx());
        transfer::public_share_object(manager);
        transfer::public_transfer(admin_cap, @0x10);
        transfer::public_transfer(msend, @0x10);

        scenario.end();
    }
}