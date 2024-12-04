module mtoken::msend {
    use sui::coin;
    use std::option::none;

    public struct MSEND has drop {}

    fun init(otw: MSEND, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency(
            otw,
            6,         // decimals
            b"MSEND",  // symbol
            b"MSEND",  // name
            b"MSEND",  // description
            none(),
            ctx,
        );

        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_freeze_object(metadata);
    }

    #[test_only]
    public(package) fun init_for_testing(ctx: &mut TxContext) {
        init(MSEND {}, ctx)
    }
}