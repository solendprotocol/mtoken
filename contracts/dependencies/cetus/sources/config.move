module cetus_clmm::config {
    use sui::event;
    use sui::transfer::{transfer, share_object};
    use sui::tx_context::{sender};
    use sui::vec_map::{VecMap};

    public struct AdminCap has store, key {
        id: UID,
    }
    
    public struct ProtocolFeeClaimCap has store, key {
        id: UID,
    }
    
    public struct FeeTier has copy, drop, store {
        tick_spacing: u32,
        fee_rate: u64,
    }
    
    public struct GlobalConfig has store, key {
        id: UID,
        protocol_fee_rate: u64,
        fee_tiers: VecMap<u32, FeeTier>,
        acl: cetus_clmm::acl::ACL,
        package_version: u64,
    }
    
    public struct InitConfigEvent has copy, drop {
        admin_cap_id: ID,
        global_config_id: ID,
    }
    
    public struct UpdateFeeRateEvent has copy, drop {
        old_fee_rate: u64,
        new_fee_rate: u64,
    }
    
    public struct AddFeeTierEvent has copy, drop {
        tick_spacing: u32,
        fee_rate: u64,
    }
    
    public struct UpdateFeeTierEvent has copy, drop {
        tick_spacing: u32,
        old_fee_rate: u64,
        new_fee_rate: u64,
    }
    
    public struct DeleteFeeTierEvent has copy, drop {
        tick_spacing: u32,
        fee_rate: u64,
    }
    
    public struct SetRolesEvent has copy, drop {
        member: address,
        roles: u128,
    }
    
    public struct AddRoleEvent has copy, drop {
        member: address,
        role: u8,
    }
    
    public struct RemoveRoleEvent has copy, drop {
        member: address,
        role: u8,
    }
    
    public struct RemoveMemberEvent has copy, drop {
        member: address,
    }
    
    public struct SetPackageVersion has copy, drop {
        new_version: u64,
        old_version: u64,
    }
    
    public fun acl(arg0: &GlobalConfig) : &cetus_clmm::acl::ACL {
        &arg0.acl
    }
    
    public fun add_role(_arg0: &AdminCap, arg1: &mut GlobalConfig, arg2: address, arg3: u8) {
        checked_package_version(arg1);
        cetus_clmm::acl::add_role(&mut arg1.acl, arg2, arg3);
        let v0 = AddRoleEvent{
            member : arg2, 
            role   : arg3,
        };
        event::emit<AddRoleEvent>(v0);
    }
    
    public fun get_members(arg0: &GlobalConfig) : vector<cetus_clmm::acl::Member> {
        cetus_clmm::acl::get_members(&arg0.acl)
    }
    
    public fun remove_member(_arg0: &AdminCap, arg1: &mut GlobalConfig, arg2: address) {
        checked_package_version(arg1);
        cetus_clmm::acl::remove_member(&mut arg1.acl, arg2);
        let v0 = RemoveMemberEvent{member: arg2};
        event::emit<RemoveMemberEvent>(v0);
    }
    
    public fun remove_role(_arg0: &AdminCap, arg1: &mut GlobalConfig, arg2: address, arg3: u8) {
        checked_package_version(arg1);
        cetus_clmm::acl::remove_role(&mut arg1.acl, arg2, arg3);
        let v0 = RemoveRoleEvent{
            member : arg2, 
            role   : arg3,
        };
        event::emit<RemoveRoleEvent>(v0);
    }
    
    public fun set_roles(_arg0: &AdminCap, arg1: &mut GlobalConfig, arg2: address, arg3: u128) {
        checked_package_version(arg1);
        cetus_clmm::acl::set_roles(&mut arg1.acl, arg2, arg3);
        let v0 = SetRolesEvent{
            member : arg2, 
            roles  : arg3,
        };
        event::emit<SetRolesEvent>(v0);
    }
    
    public fun add_fee_tier(arg0: &mut GlobalConfig, tick_spacing: u32, fee_rate: u64, arg3: &TxContext) {
        assert!(fee_rate <= 200000, 3);
        assert!(!sui::vec_map::contains<u32, FeeTier>(&arg0.fee_tiers, &tick_spacing), 1);
        checked_package_version(arg0);
        check_fee_tier_manager_role(arg0, sender(arg3));
        let v0 = FeeTier {
            tick_spacing : tick_spacing, 
            fee_rate     : fee_rate,
        };
        sui::vec_map::insert<u32, FeeTier>(&mut arg0.fee_tiers, tick_spacing, v0);
        let v1 = AddFeeTierEvent{
            tick_spacing : tick_spacing, 
            fee_rate     : fee_rate,
        };
        event::emit<AddFeeTierEvent>(v1);
    }
    
    public fun check_fee_tier_manager_role(arg0: &GlobalConfig, arg1: address) {
        assert!(cetus_clmm::acl::has_role(&arg0.acl, arg1, 1), 6);
    }
    
    public fun check_partner_manager_role(arg0: &GlobalConfig, arg1: address) {
        assert!(cetus_clmm::acl::has_role(&arg0.acl, arg1, 3), 7);
    }
    
    public fun check_pool_manager_role(arg0: &GlobalConfig, arg1: address) {
        assert!(cetus_clmm::acl::has_role(&arg0.acl, arg1, 0), 5);
    }
    
    public fun check_protocol_fee_claim_role(arg0: &GlobalConfig, arg1: address) {
        assert!(cetus_clmm::acl::has_role(&arg0.acl, arg1, 2), 9);
    }
    
    public fun check_rewarder_manager_role(arg0: &GlobalConfig, arg1: address) {
        assert!(cetus_clmm::acl::has_role(&arg0.acl, arg1, 4), 8);
    }
    
    public fun checked_package_version(arg0: &GlobalConfig) {
        assert!(arg0.package_version == 1, 10);
    }
    
    public fun delete_fee_tier(arg0: &mut GlobalConfig, arg1: u32, arg2: &TxContext) {
        assert!(sui::vec_map::contains<u32, FeeTier>(&arg0.fee_tiers, &arg1), 2);
        checked_package_version(arg0);
        check_fee_tier_manager_role(arg0, sender(arg2));
        let (_, v1) = sui::vec_map::remove<u32, FeeTier>(&mut arg0.fee_tiers, &arg1);
        let v2 = v1;
        let v3 = DeleteFeeTierEvent{
            tick_spacing : arg1, 
            fee_rate     : v2.fee_rate,
        };
        event::emit<DeleteFeeTierEvent>(v3);
    }
    
    public fun fee_rate(arg0: &FeeTier) : u64 {
        arg0.fee_rate
    }
    
    public fun fee_tiers(arg0: &GlobalConfig) : &VecMap<u32, FeeTier> {
        &arg0.fee_tiers
    }
    
    public fun get_fee_rate(tick_spacing: u32, arg1: &GlobalConfig) : u64 {
        assert!(sui::vec_map::contains<u32, FeeTier>(&arg1.fee_tiers, &tick_spacing), 2);
        sui::vec_map::get<u32, FeeTier>(&arg1.fee_tiers, &tick_spacing).fee_rate
    }
    
    public fun get_protocol_fee_rate(arg0: &GlobalConfig) : u64 {
        arg0.protocol_fee_rate
    }
    
    fun init(arg0: &mut TxContext) {
        let v0 = GlobalConfig {
            id                : sui::object::new(arg0), 
            protocol_fee_rate : 2000, 
            fee_tiers         : sui::vec_map::empty<u32, FeeTier>(), 
            acl               : cetus_clmm::acl::new(arg0), 
            package_version   : 1,
        };
        let v1 = AdminCap { id: sui::object::new(arg0) };
        let admin_cap_id = v1.id.to_inner();
        let mut v2 = v0;
        let global_config_id = v2.id.to_inner();
        let v3 = sender(arg0);
        set_roles(&v1, &mut v2, v3, 0 | 1 << 0 | 1 << 1 | 1 << 4 | 1 << 3);
        transfer<AdminCap>(v1, v3);
        share_object<GlobalConfig>(v2);
        let v4 = InitConfigEvent{
            admin_cap_id,
            global_config_id,
        };
        event::emit<InitConfigEvent>(v4);
    }
    
    public fun max_fee_rate() : u64 {
        200000
    }
    
    public fun max_protocol_fee_rate() : u64 {
        3000
    }
    
    public fun protocol_fee_rate(arg0: &GlobalConfig) : u64 {
        arg0.protocol_fee_rate
    }
    
    public fun tick_spacing(arg0: &FeeTier) : u32 {
        arg0.tick_spacing
    }
    
    public fun update_fee_tier(arg0: &mut GlobalConfig, arg1: u32, arg2: u64, arg3: &TxContext) {
        assert!(sui::vec_map::contains<u32, FeeTier>(&arg0.fee_tiers, &arg1), 2);
        assert!(arg2 <= 200000, 3);
        checked_package_version(arg0);
        check_fee_tier_manager_role(arg0, sender(arg3));
        let v0 = sui::vec_map::get_mut<u32, FeeTier>(&mut arg0.fee_tiers, &arg1);
        v0.fee_rate = arg2;
        let v1 = UpdateFeeTierEvent{
            tick_spacing : arg1, 
            old_fee_rate : v0.fee_rate, 
            new_fee_rate : arg2,
        };
        event::emit<UpdateFeeTierEvent>(v1);
    }
    
    public fun update_package_version(_arg0: &AdminCap, arg1: &mut GlobalConfig, arg2: u64) {
        arg1.package_version = arg2;
        let v0 = SetPackageVersion{
            new_version : arg2, 
            old_version : arg1.package_version,
        };
        event::emit<SetPackageVersion>(v0);
    }
    
    public fun update_protocol_fee_rate(arg0: &mut GlobalConfig, arg1: u64, arg2: &TxContext) {
        assert!(arg1 <= 3000, 4);
        checked_package_version(arg0);
        check_pool_manager_role(arg0, sender(arg2));
        arg0.protocol_fee_rate = arg1;
        let v0 = UpdateFeeRateEvent{
            old_fee_rate : arg0.protocol_fee_rate, 
            new_fee_rate : arg1,
        };
        event::emit<UpdateFeeRateEvent>(v0);
    }
    
    // decompiled from Move bytecode v6

    #[test_only]
    public fun init_for_testing(arg0: &mut TxContext): (GlobalConfig, AdminCap) {
        let v0 = GlobalConfig {
            id                : sui::object::new(arg0), 
            protocol_fee_rate : 2000, 
            fee_tiers         : sui::vec_map::empty<u32, FeeTier>(), 
            acl               : cetus_clmm::acl::new(arg0), 
            package_version   : 1,
        };
        let v1 = AdminCap { id: sui::object::new(arg0) };
        let mut v2 = v0;
        let v3 = sender(arg0);
        set_roles(&v1, &mut v2, v3, 0 | 1 << 0 | 1 << 1 | 1 << 4 | 1 << 3);
        (v2, v1)
    }
}

