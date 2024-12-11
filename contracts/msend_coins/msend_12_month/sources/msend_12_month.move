module msend_12_month::msend_12_month {
    use sui::{coin, url};
    use std::option::{some};

    public struct MSEND_12_MONTH has drop {}

    const NAME: vector<u8> = b"mSEND Series 3";
    const SYMBOL: vector<u8> = b"mSEND";
    const DESCRIPTION: vector<u8> = b"mSEND(2024/12/12-2025/12/12) SUI 0.37->0";
    const DECIMALS: u8 = 6;
    const LOGO_URL: vector<u8> = b"https://suilend-assets.s3.us-east-2.amazonaws.com/SEND/mSEND.svg";

    fun init(otw: MSEND_12_MONTH, ctx: &mut TxContext) {
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