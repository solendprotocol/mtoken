module mtoken::send {
    // use sui::url;
    use sui::coin;

    public struct SEND has drop {}

    fun init(witness: SEND, ctx: &mut TxContext) {
        let (mut treasury, metadata) = coin::create_currency(
            witness,
            6,
            b"SEND", // ticker
            b"SEND", // name
            b"SEND", // Description
            // option::some(url::new_unsafe_from_bytes(b"https://suilend-assets.s3.us-east-2.amazonaws.com/suilend_points.png")),
            option::none(), // TODO
            ctx
        );

        let coin = coin::mint(&mut treasury, 100_000_000_000 * 1_000_000, ctx);

        transfer::public_freeze_object(metadata);
        transfer::public_transfer(coin, tx_context::sender(ctx));
        transfer::public_transfer(treasury, tx_context::sender(ctx));
    }

    #[test_only]
    public(package) fun init_for_testing(ctx: &mut TxContext) {
        init(SEND {}, ctx)
    }
}