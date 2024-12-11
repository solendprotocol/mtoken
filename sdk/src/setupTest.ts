import { Transaction } from "@mysten/sui/transactions";
import { TickMath } from "@cetusprotocol/cetus-sui-clmm-sdk";
import {
  CETUS_GLOBAL_CONFIG,
  CETUS_PKG,
  POOLS_REGISTRY,
  SEND_TREASURY_CAP,
  SEND_TYPE,
  SUI_TREASURY_CAP,
  SUI_TYPE,
  TICK_SPACING,
} from "./consts";
import { SUI_CLOCK_OBJECT_ID } from "@mysten/sui/utils";
import { getKeypair } from "./utils";
import {
  DevInspectResults,
  getFullnodeUrl,
  SuiClient,
} from "@mysten/sui/client";

function setupPool(sender: string, transaction: Transaction) {
  const suiLiquidity = BigInt("859622001237312227");

  // Mint test SUI coins
  const [suiCoin] = transaction.moveCall({
    target: `0x2::coin::mint`,
    typeArguments: [SUI_TYPE],
    arguments: [
      transaction.object(SUI_TREASURY_CAP),
      transaction.pure.u64(suiLiquidity),
    ],
  });

  // Mint test SEND coins
  const [sendCoin] = transaction.moveCall({
    target: `0x2::coin::mint`,
    typeArguments: [SEND_TYPE],
    arguments: [
      transaction.object(SEND_TREASURY_CAP),
      transaction.pure.u64(20_000_000_000 * (10 ^ 6)),
    ],
  });

  // Setup fee rate
  transaction.moveCall({
    target: `${CETUS_PKG}::config::add_fee_tier`,
    arguments: [
      transaction.object(CETUS_GLOBAL_CONFIG),
      transaction.pure.u32(TICK_SPACING),
      transaction.pure.u64(10000), // FEE RATE 10_000 BPS
    ],
  });

  const initialSqrtPrice = BigInt(
    TickMath.tickIndexToSqrtPriceX64(46000).toString()
  ); // Price = 0.1

  // Create pool
  const [position, coinSend, coinSui] = transaction.moveCall({
    target: `${CETUS_PKG}::factory::create_pool_with_liquidity`,
    typeArguments: [SEND_TYPE, SUI_TYPE],
    arguments: [
      transaction.object(POOLS_REGISTRY),
      transaction.object(CETUS_GLOBAL_CONFIG),
      transaction.pure.u32(TICK_SPACING),
      transaction.pure.u128(initialSqrtPrice),
      transaction.pure.string("hello test"),
      transaction.pure.u32(39000), // lower tick index = 0.05
      transaction.pure.u32(69000), // upper tick index = 1.0
      transaction.object(sendCoin),
      transaction.object(suiCoin),
      transaction.pure.u64(20_000_000_000 * (10 ^ 6)), // SEND liquidity amount
      transaction.pure.u64(suiLiquidity), // SUI liquidity amount
      transaction.pure.bool(true), // from_a
      transaction.object(SUI_CLOCK_OBJECT_ID),
    ],
  });

  transaction.transferObjects([position, coinSend, coinSui], sender);
  // transaction.transferObjects([suiCoin, sendCoin], sender);
}

const keypair = getKeypair();
const addy = keypair.getPublicKey().toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl("testnet") });

const txb = new Transaction();

setupPool(addy, txb);

const inspectResults: DevInspectResults =
  await client.devInspectTransactionBlock({
    sender: addy,
    transactionBlock: txb,
  });

// console.log(inspectResults);

if (inspectResults.effects.status.status === "success") {
  const result = await client.signAndExecuteTransaction({
    transaction: txb,
    signer: keypair,
    options: {
      showEffects: true,
      showEvents: true,
    },
  });

  console.log(result);
  if (result.errors) {
    throw new Error(`Transaction failed`);
  } else {
    console.log(`Transaction succeded`);
  }
} else {
  console.log(inspectResults);
  throw new Error("Dry Run failed");
}
