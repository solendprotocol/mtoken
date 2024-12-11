import { Transaction } from "@mysten/sui/transactions";
import { CETUS_POOL, MTOKEN_MANAGER, TICK_SPACING } from "./consts";
import { getKeypair } from "./utils";
import {
  DevInspectResults,
  getFullnodeUrl,
  SuiClient,
} from "@mysten/sui/client";
import { flashLoan } from "./flashLoan";

const keypair = getKeypair();
const addy = keypair.getPublicKey().toSuiAddress();

const client = new SuiClient({ url: getFullnodeUrl("testnet") });
const txb = new Transaction();

flashLoan({
  pool: CETUS_POOL,
  suiPenaltyAmount: 100, // Without decimals - sui amount OUT
  minPrice: 0.01, // based on slippage
  sourceMSendCoin:
    "0x4bd0d6fd7f186c2015f700ff267bc38f33db1b38af4bab3545c4745d1f4025df",
  burnAmount: 1_000_000, // without decimals - msend amount to burn
  mTokenManager: MTOKEN_MANAGER,
  tickSpacing: TICK_SPACING,
  transaction: txb,
});

const inspectResults: DevInspectResults =
  await client.devInspectTransactionBlock({
    sender: addy,
    transactionBlock: txb,
  });

console.log(inspectResults);

// if (inspectResults.effects.status.status === "success") {
//   const result = await client.signAndExecuteTransaction({
//     transaction: txb,
//     signer: keypair,
//     options: {
//       showEffects: true,
//       showEvents: true,
//     },
//   });

//   console.log(result);
//   if (result.errors) {
//     throw new Error(`Transaction failed`);
//   } else {
//     console.log(`Transaction succeded`);
//   }
// } else {
//   console.log(inspectResults);
//   throw new Error("Dry Run failed");
// }
