#[test_only]
module mtoken::underlying {
    use sui::coin::{Self, TreasuryCap, CoinMetadata};

    public struct UNDERLYING has drop {}

    #[test_only]
    public fun create_currency(ctx: &mut TxContext): (
        TreasuryCap<UNDERLYING>, 
        CoinMetadata<UNDERLYING>, 
    ) {
        coin::create_currency(
            UNDERLYING {}, 
            6, 
            vector::empty(),
            vector::empty(),
            vector::empty(),
            option::none(),
            ctx
        )
    }
}

#[test_only]
module mtoken::vest {
    public struct VEST has drop {}
}
