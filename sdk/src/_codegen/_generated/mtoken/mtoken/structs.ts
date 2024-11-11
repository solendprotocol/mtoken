import {Balance} from "../../_dependencies/source/0x2/balance/structs";
import {TreasuryCap} from "../../_dependencies/source/0x2/coin/structs";
import {ID, UID} from "../../_dependencies/source/0x2/object/structs";
import {PhantomReified, PhantomToTypeStr, PhantomTypeArgument, Reified, StructClass, ToField, ToPhantomTypeArgument, ToTypeStr, assertFieldsWithTypesArgsMatch, assertReifiedTypeArgsMatch, decodeFromFields, decodeFromFieldsWithTypes, decodeFromJSONField, extractType, phantom} from "../../_framework/reified";
import {FieldsWithTypes, composeSuiType, compressSuiType, parseTypeName} from "../../_framework/util";
import {PKG_V1} from "../index";
import {bcs} from "@mysten/sui/bcs";
import {SuiClient, SuiObjectData, SuiParsedData} from "@mysten/sui/client";
import {fromB64} from "@mysten/sui/utils";

/* ============================== AdminCap =============================== */

export function isAdminCap(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::mtoken::AdminCap` + '<'); }

export interface AdminCapFields<MToken extends PhantomTypeArgument, Vesting extends PhantomTypeArgument, Penalty extends PhantomTypeArgument> { id: ToField<UID>; manager: ToField<ID> }

export type AdminCapReified<MToken extends PhantomTypeArgument, Vesting extends PhantomTypeArgument, Penalty extends PhantomTypeArgument> = Reified< AdminCap<MToken, Vesting, Penalty>, AdminCapFields<MToken, Vesting, Penalty> >;

export class AdminCap<MToken extends PhantomTypeArgument, Vesting extends PhantomTypeArgument, Penalty extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::mtoken::AdminCap`; static readonly $numTypeParams = 3; static readonly $isPhantom = [true,true,true,] as const;

 readonly $typeName = AdminCap.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::mtoken::AdminCap<${PhantomToTypeStr<MToken>}, ${PhantomToTypeStr<Vesting>}, ${PhantomToTypeStr<Penalty>}>`; readonly $typeArgs: [PhantomToTypeStr<MToken>, PhantomToTypeStr<Vesting>, PhantomToTypeStr<Penalty>]; readonly $isPhantom = AdminCap.$isPhantom;

 readonly id: ToField<UID>; readonly manager: ToField<ID>

 private constructor(typeArgs: [PhantomToTypeStr<MToken>, PhantomToTypeStr<Vesting>, PhantomToTypeStr<Penalty>], fields: AdminCapFields<MToken, Vesting, Penalty>, ) { this.$fullTypeName = composeSuiType( AdminCap.$typeName, ...typeArgs ) as `${typeof PKG_V1}::mtoken::AdminCap<${PhantomToTypeStr<MToken>}, ${PhantomToTypeStr<Vesting>}, ${PhantomToTypeStr<Penalty>}>`; this.$typeArgs = typeArgs;

 this.id = fields.id;; this.manager = fields.manager; }

 static reified<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( MToken: MToken, Vesting: Vesting, Penalty: Penalty ): AdminCapReified<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return { typeName: AdminCap.$typeName, fullTypeName: composeSuiType( AdminCap.$typeName, ...[extractType(MToken), extractType(Vesting), extractType(Penalty)] ) as `${typeof PKG_V1}::mtoken::AdminCap<${PhantomToTypeStr<ToPhantomTypeArgument<MToken>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Vesting>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Penalty>>}>`, typeArgs: [ extractType(MToken), extractType(Vesting), extractType(Penalty) ] as [PhantomToTypeStr<ToPhantomTypeArgument<MToken>>, PhantomToTypeStr<ToPhantomTypeArgument<Vesting>>, PhantomToTypeStr<ToPhantomTypeArgument<Penalty>>], isPhantom: AdminCap.$isPhantom, reifiedTypeArgs: [MToken, Vesting, Penalty], fromFields: (fields: Record<string, any>) => AdminCap.fromFields( [MToken, Vesting, Penalty], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => AdminCap.fromFieldsWithTypes( [MToken, Vesting, Penalty], item, ), fromBcs: (data: Uint8Array) => AdminCap.fromBcs( [MToken, Vesting, Penalty], data, ), bcs: AdminCap.bcs, fromJSONField: (field: any) => AdminCap.fromJSONField( [MToken, Vesting, Penalty], field, ), fromJSON: (json: Record<string, any>) => AdminCap.fromJSON( [MToken, Vesting, Penalty], json, ), fromSuiParsedData: (content: SuiParsedData) => AdminCap.fromSuiParsedData( [MToken, Vesting, Penalty], content, ), fromSuiObjectData: (content: SuiObjectData) => AdminCap.fromSuiObjectData( [MToken, Vesting, Penalty], content, ), fetch: async (client: SuiClient, id: string) => AdminCap.fetch( client, [MToken, Vesting, Penalty], id, ), new: ( fields: AdminCapFields<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>>, ) => { return new AdminCap( [extractType(MToken), extractType(Vesting), extractType(Penalty)], fields ) }, kind: "StructClassReified", } }

 static get r() { return AdminCap.reified }

 static phantom<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( MToken: MToken, Vesting: Vesting, Penalty: Penalty ): PhantomReified<ToTypeStr<AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>>>> { return phantom(AdminCap.reified( MToken, Vesting, Penalty )); } static get p() { return AdminCap.phantom }

 static get bcs() { return bcs.struct("AdminCap", {

 id: UID.bcs, manager: ID.bcs

}) };

 static fromFields<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], fields: Record<string, any> ): AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return AdminCap.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { id: decodeFromFields(UID.reified(), fields.id), manager: decodeFromFields(ID.reified(), fields.manager) } ) }

 static fromFieldsWithTypes<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], item: FieldsWithTypes ): AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (!isAdminCap(item.type)) { throw new Error("not a AdminCap type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return AdminCap.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { id: decodeFromFieldsWithTypes(UID.reified(), item.fields.id), manager: decodeFromFieldsWithTypes(ID.reified(), item.fields.manager) } ) }

 static fromBcs<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], data: Uint8Array ): AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return AdminCap.fromFields( typeArgs, AdminCap.bcs.parse(data) ) }

 toJSONField() { return {

 id: this.id,manager: this.manager,

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], field: any ): AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return AdminCap.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { id: decodeFromJSONField(UID.reified(), field.id), manager: decodeFromJSONField(ID.reified(), field.manager) } ) }

 static fromJSON<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], json: Record<string, any> ): AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (json.$typeName !== AdminCap.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(AdminCap.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return AdminCap.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], content: SuiParsedData ): AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isAdminCap(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a AdminCap object`); } return AdminCap.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], data: SuiObjectData ): AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isAdminCap(data.bcs.type)) { throw new Error(`object at is not a AdminCap object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 3) { throw new Error(`type argument mismatch: expected 3 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 3; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return AdminCap.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return AdminCap.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArgs: [MToken, Vesting, Penalty], id: string ): Promise<AdminCap<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching AdminCap object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isAdminCap(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a AdminCap object`); }

 return AdminCap.fromSuiObjectData( typeArgs, res.data ); }

 }

/* ============================== VestingManager =============================== */

export function isVestingManager(type: string): boolean { type = compressSuiType(type); return type.startsWith(`${PKG_V1}::mtoken::VestingManager` + '<'); }

export interface VestingManagerFields<MToken extends PhantomTypeArgument, Vesting extends PhantomTypeArgument, Penalty extends PhantomTypeArgument> { id: ToField<UID>; vestingBalance: ToField<Balance<Vesting>>; penaltyBalance: ToField<Balance<Penalty>>; mtokenTreasuryCap: ToField<TreasuryCap<MToken>>; startPenaltyNumerator: ToField<"u64">; endPenaltyNumerator: ToField<"u64">; penaltyDenominator: ToField<"u64">; startTimeS: ToField<"u64">; endTimeS: ToField<"u64"> }

export type VestingManagerReified<MToken extends PhantomTypeArgument, Vesting extends PhantomTypeArgument, Penalty extends PhantomTypeArgument> = Reified< VestingManager<MToken, Vesting, Penalty>, VestingManagerFields<MToken, Vesting, Penalty> >;

export class VestingManager<MToken extends PhantomTypeArgument, Vesting extends PhantomTypeArgument, Penalty extends PhantomTypeArgument> implements StructClass { __StructClass = true as const;

 static readonly $typeName = `${PKG_V1}::mtoken::VestingManager`; static readonly $numTypeParams = 3; static readonly $isPhantom = [true,true,true,] as const;

 readonly $typeName = VestingManager.$typeName; readonly $fullTypeName: `${typeof PKG_V1}::mtoken::VestingManager<${PhantomToTypeStr<MToken>}, ${PhantomToTypeStr<Vesting>}, ${PhantomToTypeStr<Penalty>}>`; readonly $typeArgs: [PhantomToTypeStr<MToken>, PhantomToTypeStr<Vesting>, PhantomToTypeStr<Penalty>]; readonly $isPhantom = VestingManager.$isPhantom;

 readonly id: ToField<UID>; readonly vestingBalance: ToField<Balance<Vesting>>; readonly penaltyBalance: ToField<Balance<Penalty>>; readonly mtokenTreasuryCap: ToField<TreasuryCap<MToken>>; readonly startPenaltyNumerator: ToField<"u64">; readonly endPenaltyNumerator: ToField<"u64">; readonly penaltyDenominator: ToField<"u64">; readonly startTimeS: ToField<"u64">; readonly endTimeS: ToField<"u64">

 private constructor(typeArgs: [PhantomToTypeStr<MToken>, PhantomToTypeStr<Vesting>, PhantomToTypeStr<Penalty>], fields: VestingManagerFields<MToken, Vesting, Penalty>, ) { this.$fullTypeName = composeSuiType( VestingManager.$typeName, ...typeArgs ) as `${typeof PKG_V1}::mtoken::VestingManager<${PhantomToTypeStr<MToken>}, ${PhantomToTypeStr<Vesting>}, ${PhantomToTypeStr<Penalty>}>`; this.$typeArgs = typeArgs;

 this.id = fields.id;; this.vestingBalance = fields.vestingBalance;; this.penaltyBalance = fields.penaltyBalance;; this.mtokenTreasuryCap = fields.mtokenTreasuryCap;; this.startPenaltyNumerator = fields.startPenaltyNumerator;; this.endPenaltyNumerator = fields.endPenaltyNumerator;; this.penaltyDenominator = fields.penaltyDenominator;; this.startTimeS = fields.startTimeS;; this.endTimeS = fields.endTimeS; }

 static reified<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( MToken: MToken, Vesting: Vesting, Penalty: Penalty ): VestingManagerReified<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return { typeName: VestingManager.$typeName, fullTypeName: composeSuiType( VestingManager.$typeName, ...[extractType(MToken), extractType(Vesting), extractType(Penalty)] ) as `${typeof PKG_V1}::mtoken::VestingManager<${PhantomToTypeStr<ToPhantomTypeArgument<MToken>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Vesting>>}, ${PhantomToTypeStr<ToPhantomTypeArgument<Penalty>>}>`, typeArgs: [ extractType(MToken), extractType(Vesting), extractType(Penalty) ] as [PhantomToTypeStr<ToPhantomTypeArgument<MToken>>, PhantomToTypeStr<ToPhantomTypeArgument<Vesting>>, PhantomToTypeStr<ToPhantomTypeArgument<Penalty>>], isPhantom: VestingManager.$isPhantom, reifiedTypeArgs: [MToken, Vesting, Penalty], fromFields: (fields: Record<string, any>) => VestingManager.fromFields( [MToken, Vesting, Penalty], fields, ), fromFieldsWithTypes: (item: FieldsWithTypes) => VestingManager.fromFieldsWithTypes( [MToken, Vesting, Penalty], item, ), fromBcs: (data: Uint8Array) => VestingManager.fromBcs( [MToken, Vesting, Penalty], data, ), bcs: VestingManager.bcs, fromJSONField: (field: any) => VestingManager.fromJSONField( [MToken, Vesting, Penalty], field, ), fromJSON: (json: Record<string, any>) => VestingManager.fromJSON( [MToken, Vesting, Penalty], json, ), fromSuiParsedData: (content: SuiParsedData) => VestingManager.fromSuiParsedData( [MToken, Vesting, Penalty], content, ), fromSuiObjectData: (content: SuiObjectData) => VestingManager.fromSuiObjectData( [MToken, Vesting, Penalty], content, ), fetch: async (client: SuiClient, id: string) => VestingManager.fetch( client, [MToken, Vesting, Penalty], id, ), new: ( fields: VestingManagerFields<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>>, ) => { return new VestingManager( [extractType(MToken), extractType(Vesting), extractType(Penalty)], fields ) }, kind: "StructClassReified", } }

 static get r() { return VestingManager.reified }

 static phantom<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( MToken: MToken, Vesting: Vesting, Penalty: Penalty ): PhantomReified<ToTypeStr<VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>>>> { return phantom(VestingManager.reified( MToken, Vesting, Penalty )); } static get p() { return VestingManager.phantom }

 static get bcs() { return bcs.struct("VestingManager", {

 id: UID.bcs, vesting_balance: Balance.bcs, penalty_balance: Balance.bcs, mtoken_treasury_cap: TreasuryCap.bcs, start_penalty_numerator: bcs.u64(), end_penalty_numerator: bcs.u64(), penalty_denominator: bcs.u64(), start_time_s: bcs.u64(), end_time_s: bcs.u64()

}) };

 static fromFields<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], fields: Record<string, any> ): VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return VestingManager.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { id: decodeFromFields(UID.reified(), fields.id), vestingBalance: decodeFromFields(Balance.reified(typeArgs[1]), fields.vesting_balance), penaltyBalance: decodeFromFields(Balance.reified(typeArgs[2]), fields.penalty_balance), mtokenTreasuryCap: decodeFromFields(TreasuryCap.reified(typeArgs[0]), fields.mtoken_treasury_cap), startPenaltyNumerator: decodeFromFields("u64", fields.start_penalty_numerator), endPenaltyNumerator: decodeFromFields("u64", fields.end_penalty_numerator), penaltyDenominator: decodeFromFields("u64", fields.penalty_denominator), startTimeS: decodeFromFields("u64", fields.start_time_s), endTimeS: decodeFromFields("u64", fields.end_time_s) } ) }

 static fromFieldsWithTypes<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], item: FieldsWithTypes ): VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (!isVestingManager(item.type)) { throw new Error("not a VestingManager type");

 } assertFieldsWithTypesArgsMatch(item, typeArgs);

 return VestingManager.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { id: decodeFromFieldsWithTypes(UID.reified(), item.fields.id), vestingBalance: decodeFromFieldsWithTypes(Balance.reified(typeArgs[1]), item.fields.vesting_balance), penaltyBalance: decodeFromFieldsWithTypes(Balance.reified(typeArgs[2]), item.fields.penalty_balance), mtokenTreasuryCap: decodeFromFieldsWithTypes(TreasuryCap.reified(typeArgs[0]), item.fields.mtoken_treasury_cap), startPenaltyNumerator: decodeFromFieldsWithTypes("u64", item.fields.start_penalty_numerator), endPenaltyNumerator: decodeFromFieldsWithTypes("u64", item.fields.end_penalty_numerator), penaltyDenominator: decodeFromFieldsWithTypes("u64", item.fields.penalty_denominator), startTimeS: decodeFromFieldsWithTypes("u64", item.fields.start_time_s), endTimeS: decodeFromFieldsWithTypes("u64", item.fields.end_time_s) } ) }

 static fromBcs<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], data: Uint8Array ): VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return VestingManager.fromFields( typeArgs, VestingManager.bcs.parse(data) ) }

 toJSONField() { return {

 id: this.id,vestingBalance: this.vestingBalance.toJSONField(),penaltyBalance: this.penaltyBalance.toJSONField(),mtokenTreasuryCap: this.mtokenTreasuryCap.toJSONField(),startPenaltyNumerator: this.startPenaltyNumerator.toString(),endPenaltyNumerator: this.endPenaltyNumerator.toString(),penaltyDenominator: this.penaltyDenominator.toString(),startTimeS: this.startTimeS.toString(),endTimeS: this.endTimeS.toString(),

} }

 toJSON() { return { $typeName: this.$typeName, $typeArgs: this.$typeArgs, ...this.toJSONField() } }

 static fromJSONField<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], field: any ): VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { return VestingManager.reified( typeArgs[0], typeArgs[1], typeArgs[2], ).new( { id: decodeFromJSONField(UID.reified(), field.id), vestingBalance: decodeFromJSONField(Balance.reified(typeArgs[1]), field.vestingBalance), penaltyBalance: decodeFromJSONField(Balance.reified(typeArgs[2]), field.penaltyBalance), mtokenTreasuryCap: decodeFromJSONField(TreasuryCap.reified(typeArgs[0]), field.mtokenTreasuryCap), startPenaltyNumerator: decodeFromJSONField("u64", field.startPenaltyNumerator), endPenaltyNumerator: decodeFromJSONField("u64", field.endPenaltyNumerator), penaltyDenominator: decodeFromJSONField("u64", field.penaltyDenominator), startTimeS: decodeFromJSONField("u64", field.startTimeS), endTimeS: decodeFromJSONField("u64", field.endTimeS) } ) }

 static fromJSON<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], json: Record<string, any> ): VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (json.$typeName !== VestingManager.$typeName) { throw new Error("not a WithTwoGenerics json object") }; assertReifiedTypeArgsMatch( composeSuiType(VestingManager.$typeName, ...typeArgs.map(extractType)), json.$typeArgs, typeArgs, )

 return VestingManager.fromJSONField( typeArgs, json, ) }

 static fromSuiParsedData<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], content: SuiParsedData ): VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (content.dataType !== "moveObject") { throw new Error("not an object"); } if (!isVestingManager(content.type)) { throw new Error(`object at ${(content.fields as any).id} is not a VestingManager object`); } return VestingManager.fromFieldsWithTypes( typeArgs, content ); }

 static fromSuiObjectData<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( typeArgs: [MToken, Vesting, Penalty], data: SuiObjectData ): VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>> { if (data.bcs) { if (data.bcs.dataType !== "moveObject" || !isVestingManager(data.bcs.type)) { throw new Error(`object at is not a VestingManager object`); }

 const gotTypeArgs = parseTypeName(data.bcs.type).typeArgs; if (gotTypeArgs.length !== 3) { throw new Error(`type argument mismatch: expected 3 type arguments but got ${gotTypeArgs.length}`); }; for (let i = 0; i < 3; i++) { const gotTypeArg = compressSuiType(gotTypeArgs[i]); const expectedTypeArg = compressSuiType(extractType(typeArgs[i])); if (gotTypeArg !== expectedTypeArg) { throw new Error(`type argument mismatch at position ${i}: expected '${expectedTypeArg}' but got '${gotTypeArg}'`); } };

 return VestingManager.fromBcs( typeArgs, fromB64(data.bcs.bcsBytes) ); } if (data.content) { return VestingManager.fromSuiParsedData( typeArgs, data.content ) } throw new Error( "Both `bcs` and `content` fields are missing from the data. Include `showBcs` or `showContent` in the request." ); }

 static async fetch<MToken extends PhantomReified<PhantomTypeArgument>, Vesting extends PhantomReified<PhantomTypeArgument>, Penalty extends PhantomReified<PhantomTypeArgument>>( client: SuiClient, typeArgs: [MToken, Vesting, Penalty], id: string ): Promise<VestingManager<ToPhantomTypeArgument<MToken>, ToPhantomTypeArgument<Vesting>, ToPhantomTypeArgument<Penalty>>> { const res = await client.getObject({ id, options: { showBcs: true, }, }); if (res.error) { throw new Error(`error fetching VestingManager object at id ${id}: ${res.error.code}`); } if (res.data?.bcs?.dataType !== "moveObject" || !isVestingManager(res.data.bcs.type)) { throw new Error(`object at id ${id} is not a VestingManager object`); }

 return VestingManager.fromSuiObjectData( typeArgs, res.data ); }

 }
