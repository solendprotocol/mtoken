// import { GenericArg, generic, obj, pure } from "../../_framework/util";
import {
  DevInspectResults,
  getFullnodeUrl,
  SuiClient,
} from "@mysten/sui/client";
import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import {
  Transaction,
  TransactionArgument,
  TransactionObjectInput,
} from "@mysten/sui/transactions";
import { bech32 } from "bech32";
import { getKeypair } from "./utils";
import {
  MSEND_TREASURY_CAP,
  MSEND_TYPE,
  MTOKEN_PKG,
  SEND_TYPE,
  SUI_TYPE,
} from "./consts";

const SEND_COIN =
  "0x780898dd623e1fb2844241cbd90e06132abcc57a33bda3bca23db012b6f300ae";

const START_PENALTY_NUMERATOR = 10;
const END_PENALTY_NUMERATOR = 10;
const PENALTY_DENOMINATOR = 100_000;
const START_TIME_TS_SECONDS = 1733311191;
const END_TIME_TS_SECONDS = 1734002391;

export interface MintMtokensArgs {
  treasuryCap: TransactionObjectInput;
  vestingCoin: TransactionObjectInput;
  startPenaltyNumerator: number;
  endPenaltyNumerator: number;
  penaltyDenominator: number;
  startTimeS: number;
  endTimeS: number;
}

export function mintMtokens(
  tx: Transaction,
  sender: string,
  pkgId: string,
  typeArgs: [string, string, string],
  args: MintMtokensArgs
) {
  const [adminCap, vestingManager, msend] = tx.moveCall({
    target: `${pkgId}::mtoken::mint_mtokens`,
    typeArguments: typeArgs,
    arguments: [
      tx.object(args.treasuryCap),
      tx.object(args.vestingCoin),
      tx.pure.u64(args.startPenaltyNumerator),
      tx.pure.u64(args.endPenaltyNumerator),
      tx.pure.u64(args.penaltyDenominator),
      tx.pure.u64(args.startTimeS),
      tx.pure.u64(args.endTimeS),
    ],
  });

  tx.transferObjects([adminCap, msend], sender);
  tx.moveCall({
    target: `0x2::transfer::public_share_object`,
    typeArguments: [
      `${pkgId}::mtoken::VestingManager<${MSEND_TYPE}, ${SEND_TYPE}, ${SUI_TYPE}>`,
    ],
    arguments: [vestingManager],
  });
}

const keypair = getKeypair();
const addy = keypair.getPublicKey().toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl("testnet") });

const txb = new Transaction();

mintMtokens(txb, addy, MTOKEN_PKG, [MSEND_TYPE, SEND_TYPE, SUI_TYPE], {
  treasuryCap: MSEND_TREASURY_CAP,
  vestingCoin: SEND_COIN,
  startPenaltyNumerator: START_PENALTY_NUMERATOR,
  endPenaltyNumerator: END_PENALTY_NUMERATOR,
  penaltyDenominator: PENALTY_DENOMINATOR,
  startTimeS: START_TIME_TS_SECONDS,
  endTimeS: END_TIME_TS_SECONDS,
});

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
