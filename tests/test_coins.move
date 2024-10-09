#[test_only]
module vesting::vested_coin {
    use sui::coin::{Self, TreasuryCap, CoinMetadata};

    public struct VESTED_COIN has drop {}

    #[test_only]
    public fun create_currency(ctx: &mut TxContext): (
        TreasuryCap<VESTED_COIN>, 
        CoinMetadata<VESTED_COIN>, 
    ) {
        coin::create_currency(
            VESTED_COIN {}, 
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
module vesting::option_coin {
    public struct OPTION_COIN has drop {}
}
