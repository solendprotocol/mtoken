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

const PKG_ID =
  "0xd0d8ed2a83da2f0f171de7d60b0b128637d51e6dbfbec232447a764cdc6af627";

const MSEND_TYPE =
  "0x1a98c181ce323d1571be1f805b3d5d19e98c1f79492aa32f592e7fd4575fd9e2::msend::MSEND";
const SEND_TYPE =
  "0x1a98c181ce323d1571be1f805b3d5d19e98c1f79492aa32f592e7fd4575fd9e2::send::SEND";
const SUI_TYPE = "0x2::sui::SUI";

const MSEND_TREASURY_CAP =
  "0xedd96f3b4fe682f6f64dc534f99d13239ff9638e8de24b90a3d4506b4c2f1c69";
const SEND_COIN =
  "0x500926150a5dc21e26f8f389164bdaf542b816e713a7cbd8e6e9bd6e7549990e";

const START_PENALTY_NUMERATOR = 10;
const END_PENALTY_NUMERATOR = 1;
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

function getKeypair(isTest: boolean): Ed25519Keypair {
  return isTest
    ? loadSuiKeypair(process.env.BETA_WALLET_KEY)
    : loadSuiKeypair(process.env.MAINNET_WALLET_KEY);
}

export function loadSuiKeypair(
  bech32String: string | undefined
): Ed25519Keypair {
  if (!bech32String || !bech32String.startsWith("suiprivkey1")) {
    throw new Error(
      `Invalid private key format: Expected prefix 'suiprivkey1', but received '${bech32String}'`
    );
  }

  // Decode the Bech32 encoded key
  const decoded = bech32.decode(bech32String);
  let privateKeyBytes = bech32.fromWords(decoded.words);

  // Ensure the private key is exactly 32 bytes (Ed25519 key size)
  if (privateKeyBytes.length === 33) {
    privateKeyBytes = privateKeyBytes.slice(1); // Remove the first extra byte
  } else if (privateKeyBytes.length !== 32) {
    throw new Error(
      `Invalid private key length: Expected 32 bytes, got ${privateKeyBytes.length}`
    );
  }

  return Ed25519Keypair.fromSecretKey(Uint8Array.from(privateKeyBytes));
}

const keypair = getKeypair(true); // true == isTest
const addy = keypair.getPublicKey().toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl("mainnet") });

const txb = new Transaction();

mintMtokens(txb, addy, PKG_ID, [MSEND_TYPE, SEND_TYPE, SUI_TYPE], {
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
