import {PUBLISHED_AT} from "..";
import {GenericArg, generic, obj, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export interface CollectPenaltiesArgs { manager: TransactionObjectInput; adminCap: TransactionObjectInput }

export function collectPenalties( tx: Transaction, typeArgs: [string, string, string], args: CollectPenaltiesArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::collect_penalties`, typeArguments: typeArgs, arguments: [ obj(tx, args.manager), obj(tx, args.adminCap) ], }) }

export function manager( tx: Transaction, typeArgs: [string, string, string], adminCap: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::manager`, typeArguments: typeArgs, arguments: [ obj(tx, adminCap) ], }) }

export function endPenaltyNumerator( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::end_penalty_numerator`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export function endTimeS( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::end_time_s`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export interface MintMtokensArgs { otw: GenericArg; vestingCoin: TransactionObjectInput; coinMeta: TransactionObjectInput; startPenaltyNumerator: bigint | TransactionArgument; endPenaltyNumerator: bigint | TransactionArgument; penaltyDenominator: bigint | TransactionArgument; startTimeS: bigint | TransactionArgument; endTimeS: bigint | TransactionArgument }

export function mintMtokens( tx: Transaction, typeArgs: [string, string, string], args: MintMtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::mint_mtokens`, typeArguments: typeArgs, arguments: [ generic(tx, `${typeArgs[0]}`, args.otw), obj(tx, args.vestingCoin), obj(tx, args.coinMeta), pure(tx, args.startPenaltyNumerator, `u64`), pure(tx, args.endPenaltyNumerator, `u64`), pure(tx, args.penaltyDenominator, `u64`), pure(tx, args.startTimeS, `u64`), pure(tx, args.endTimeS, `u64`) ], }) }

export function startPenaltyNumerator( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::start_penalty_numerator`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export function penaltyDenominator( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::penalty_denominator`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export function startTimeS( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::start_time_s`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export interface RedeemMtokensArgs { manager: TransactionObjectInput; mtokenCoin: TransactionObjectInput; penaltyCoin: TransactionObjectInput; clock: TransactionObjectInput }

export function redeemMtokens( tx: Transaction, typeArgs: [string, string, string], args: RedeemMtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::redeem_mtokens`, typeArguments: typeArgs, arguments: [ obj(tx, args.manager), obj(tx, args.mtokenCoin), obj(tx, args.penaltyCoin), obj(tx, args.clock) ], }) }
