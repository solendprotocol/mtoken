import { Ed25519Keypair } from "@mysten/sui/keypairs/ed25519";
import { bech32 } from "bech32";
import dotenv from "dotenv";

dotenv.config();

export function getKeypair(): Ed25519Keypair {
  return loadSuiKeypair(process.env.WALLET_KEY);
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
