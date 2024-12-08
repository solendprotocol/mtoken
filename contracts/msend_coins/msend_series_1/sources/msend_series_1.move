module msend_series_1::msend_series_1 {
    use sui::{coin, url};
    use std::option::{some};

    public struct MSEND_SERIES_1 has drop {}

    const NAME: vector<u8> = b"mSEND Series 1";
    const SYMBOL: vector<u8> = b"mSEND";
    const DESCRIPTION: vector<u8> = b"mSEND(2024/12/12-2025/03/12) SUI 0.25->0";
    const DECIMALS: u8 = 6;
    const LOGO_URL: vector<u8> = b"https://suilend-assets.s3.us-east-2.amazonaws.com/SEND/mSEND.svg";

    fun init(otw: MSEND_SERIES_1, ctx: &mut TxContext) {
        let logo_url = url::new_unsafe_from_bytes(LOGO_URL);

        let (treasury_cap, metadata) = coin::create_currency(
            otw,
            DECIMALS,
            SYMBOL,
            NAME,
            DESCRIPTION,
            some(logo_url),
            ctx,
        );

        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
        transfer::public_share_object(metadata);
    }
}