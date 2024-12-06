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

const CLAIM_MSEND_PKG =
  "0x3615c20d2375363f642d99cec657e69799b118d580f115760c731f0568900770";

const MSEND_TYPE =
  "0x1a98c181ce323d1571be1f805b3d5d19e98c1f79492aa32f592e7fd4575fd9e2::msend::MSEND";

const POINTS_NUMERATOR = 1;
const POINTS_DENOMINATOR = 100;

const COMMON_CAPSULE_AMOUNT = 10_000_000;
const UNCOMMON_CAPSULE_AMOUNT = 100_000_000;
const RARE_CAPSULE_AMOUNT = 1_000_000_000;

export interface CreatePointsManager {
  ratioNumerator: number;
  ratioDenominator: number;
}

export interface CreateCapsuleManager {
  commonAmount: number;
  uncommonAmount: number;
  rareAmount: number;
}

export function createManagers(
  tx: Transaction,
  sender: string,
  pkgId: string,
  pointsArgs: CreatePointsManager,
  capsuleArgs: CreateCapsuleManager
) {
  const [pointsManager, pointsAdmin] = tx.moveCall({
    target: `${pkgId}::points::new`,
    typeArguments: [MSEND_TYPE],
    arguments: [
      tx.pure.u64(pointsArgs.ratioNumerator),
      tx.pure.u64(pointsArgs.ratioDenominator),
    ],
  });

  const [capsuleManager, capsuleAdmin] = tx.moveCall({
    target: `${pkgId}::capsule::new`,
    typeArguments: [MSEND_TYPE],
    arguments: [
      tx.pure.u64(capsuleArgs.commonAmount),
      tx.pure.u64(capsuleArgs.uncommonAmount),
      tx.pure.u64(capsuleArgs.rareAmount),
    ],
  });

  tx.transferObjects([pointsAdmin, capsuleAdmin], sender);
  tx.moveCall({
    target: `0x2::transfer::public_share_object`,
    typeArguments: [`${pkgId}::points::PointsManager<${MSEND_TYPE}>`],
    arguments: [pointsManager],
  });
  tx.moveCall({
    target: `0x2::transfer::public_share_object`,
    typeArguments: [`${pkgId}::capsule::CapsuleManager<${MSEND_TYPE}>`],
    arguments: [capsuleManager],
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

createManagers(
  txb,
  addy,
  CLAIM_MSEND_PKG,
  {
    ratioNumerator: POINTS_NUMERATOR,
    ratioDenominator: POINTS_DENOMINATOR,
  },
  {
    commonAmount: COMMON_CAPSULE_AMOUNT,
    uncommonAmount: UNCOMMON_CAPSULE_AMOUNT,
    rareAmount: RARE_CAPSULE_AMOUNT,
  }
);

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
