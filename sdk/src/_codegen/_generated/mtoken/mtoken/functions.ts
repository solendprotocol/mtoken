import {PUBLISHED_AT} from "..";
import {Url} from "../../_dependencies/source/0x2/url/structs";
import {GenericArg, generic, obj, option, pure} from "../../_framework/util";
import {Transaction, TransactionArgument, TransactionObjectInput} from "@mysten/sui/transactions";

export interface CollectPenaltiesArgs { manager: TransactionObjectInput; adminCap: TransactionObjectInput }

export function collectPenalties( tx: Transaction, typeArgs: [string, string, string], args: CollectPenaltiesArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::collect_penalties`, typeArguments: typeArgs, arguments: [ obj(tx, args.manager), obj(tx, args.adminCap) ], }) }

export function manager( tx: Transaction, typeArgs: [string, string, string], adminCap: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::manager`, typeArguments: typeArgs, arguments: [ obj(tx, adminCap) ], }) }

export function endPenaltyNumerator( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::end_penalty_numerator`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export function endTimeS( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::end_time_s`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export interface InitManagerArgs { otw: GenericArg; decimals: number | TransactionArgument; symbol: Array<number | TransactionArgument> | TransactionArgument; name: Array<number | TransactionArgument> | TransactionArgument; description: Array<number | TransactionArgument> | TransactionArgument; iconUrl: (TransactionObjectInput | TransactionArgument | null); startPenaltyNumerator: bigint | TransactionArgument; endPenaltyNumerator: bigint | TransactionArgument; penaltyDenominator: bigint | TransactionArgument; startTimeS: bigint | TransactionArgument; endTimeS: bigint | TransactionArgument }

export function initManager( tx: Transaction, typeArgs: [string, string, string], args: InitManagerArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::init_manager`, typeArguments: typeArgs, arguments: [ generic(tx, `${typeArgs[0]}`, args.otw), pure(tx, args.decimals, `u8`), pure(tx, args.symbol, `vector<u8>`), pure(tx, args.name, `vector<u8>`), pure(tx, args.description, `vector<u8>`), option(tx, `${Url.$typeName}`, args.iconUrl), pure(tx, args.startPenaltyNumerator, `u64`), pure(tx, args.endPenaltyNumerator, `u64`), pure(tx, args.penaltyDenominator, `u64`), pure(tx, args.startTimeS, `u64`), pure(tx, args.endTimeS, `u64`) ], }) }

export function startPenaltyNumerator( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::start_penalty_numerator`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export function penaltyDenominator( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::penalty_denominator`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export function startTimeS( tx: Transaction, typeArgs: [string, string, string], manager: TransactionObjectInput ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::start_time_s`, typeArguments: typeArgs, arguments: [ obj(tx, manager) ], }) }

export interface MintMtokensArgs { admin: TransactionObjectInput; manager: TransactionObjectInput; vestingCoin: TransactionObjectInput }

export function mintMtokens( tx: Transaction, typeArgs: [string, string, string], args: MintMtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::mint_mtokens`, typeArguments: typeArgs, arguments: [ obj(tx, args.admin), obj(tx, args.manager), obj(tx, args.vestingCoin) ], }) }

export interface RedeemMtokensArgs { manager: TransactionObjectInput; mtokenCoin: TransactionObjectInput; penaltyCoin: TransactionObjectInput; clock: TransactionObjectInput }

export function redeemMtokens( tx: Transaction, typeArgs: [string, string, string], args: RedeemMtokensArgs ) { return tx.moveCall({ target: `${PUBLISHED_AT}::mtoken::redeem_mtokens`, typeArguments: typeArgs, arguments: [ obj(tx, args.manager), obj(tx, args.mtokenCoin), obj(tx, args.penaltyCoin), obj(tx, args.clock) ], }) }
