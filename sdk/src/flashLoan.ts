import { TickMath } from "@cetusprotocol/cetus-sui-clmm-sdk";
import { Transaction } from "@mysten/sui/transactions";
import Decimal from "decimal.js";
import {
  CETUS_GLOBAL_CONFIG,
  CETUS_PKG,
  DECIMALS_SEND,
  DECIMALS_SUI,
  MSEND_TYPE,
  MTOKEN_PKG,
  SEND_TYPE,
  SUI_TYPE,
} from "./consts";

import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui/utils";

export async function flashLoan(args: {
  pool: string;
  suiPenaltyAmount: number;
  minPrice: number; // based on slippage
  sourceMSendCoin: string;
  burnAmount: number;
  mTokenManager: string;
  tickSpacing: number;
  transaction: Transaction;
}) {
  let {
    pool,
    suiPenaltyAmount,
    minPrice,
    sourceMSendCoin,
    burnAmount,
    mTokenManager,
    tickSpacing,
    transaction,
  } = args;

  const mSendCoinToBurn = transaction.splitCoins(sourceMSendCoin, [burnAmount]);

  const minSqrtPrice = getClosestSqrtPriceFromPrice(
    minPrice,
    DECIMALS_SEND,
    DECIMALS_SUI,
    tickSpacing
  );
  const [sendBal, suiBal, receipt] = transaction.moveCall({
    target: `${CETUS_PKG}::pool::flash_swap`,
    typeArguments: [SEND_TYPE, SUI_TYPE],
    arguments: [
      transaction.object(CETUS_GLOBAL_CONFIG),
      transaction.object(pool),
      transaction.pure.bool(true), // a2b, i.e. Get SUI, pay SEND later
      transaction.pure.bool(false), // by_amount_in, false because we want to specify how much SUI we get which is equivalent to penalty amount
      transaction.pure.u64(suiPenaltyAmount),
      transaction.pure.u128(minSqrtPrice),
      transaction.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  const [penaltyCoin] = transaction.moveCall({
    target: `0x2::coin::from_balance`,
    typeArguments: [SUI_TYPE],
    arguments: [suiBal],
  });

  const [send] = transaction.moveCall({
    target: `${MTOKEN_PKG}::mtoken::redeem_mtokens`,
    typeArguments: [MSEND_TYPE, SEND_TYPE, SUI_TYPE],
    arguments: [
      transaction.object(mTokenManager),
      transaction.object(mSendCoinToBurn),
      penaltyCoin,
      transaction.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  const sendPayAmount = transaction.moveCall({
    target: `${CETUS_PKG}::pool::swap_pay_amount`,
    typeArguments: [SEND_TYPE, SUI_TYPE],
    arguments: [transaction.object(receipt)],
  });

  const sendCoinToPay = transaction.splitCoins(send, [sendPayAmount]);

  const sendBalToMerge = transaction.moveCall({
    target: `0x2::coin::into_balance`,
    typeArguments: [SEND_TYPE],
    arguments: [sendCoinToPay],
  });

  transaction.moveCall({
    target: `0x2::balance::join`,
    typeArguments: [SEND_TYPE],
    arguments: [sendBal, sendBalToMerge],
  });

  const emptySuiBalance = transaction.moveCall({
    target: `0x2::balance::zero`,
    typeArguments: [SUI_TYPE],
    arguments: [],
  });

  transaction.moveCall({
    target: `${CETUS_PKG}::pool::repay_flash_swap`,
    typeArguments: [SEND_TYPE, SUI_TYPE],
    arguments: [
      transaction.object(CETUS_GLOBAL_CONFIG),
      transaction.object(pool),
      transaction.object(sendBal),
      transaction.object(emptySuiBalance),
      receipt,
    ],
  });
}

export function getClosestTickFromPrice(
  price: number,
  decimalsA: number,
  decimalsB: number,
  tickSpacing: number
): number {
  const priceDecimal = new Decimal(price);
  const tick = TickMath.priceToTickIndex(priceDecimal, decimalsA, decimalsB);

  return closestLowerDivisibleByTickSpacing(tick, tickSpacing);
}

export function getClosestSqrtPriceFromPrice(
  price: number,
  decimalsA: number,
  decimalsB: number,
  tickSpacing: number
): bigint {
  const closestTick = getClosestTickFromPrice(
    price,
    decimalsA,
    decimalsB,
    tickSpacing
  );

  const closestSqrtPriceBN = TickMath.tickIndexToSqrtPriceX64(closestTick);
  const closestSqrtPrice = BigInt(closestSqrtPriceBN.toString());
  return closestSqrtPrice;
}

function closestLowerDivisibleByTickSpacing(
  num: number,
  tickSpacing: number
): number {
  const divisor = tickSpacing;
  const remainder = num % divisor;

  if (remainder === 0) {
    return num;
  }

  if (num > 0) {
    return num - remainder;
  } else {
    return num - remainder - divisor;
  }
}
