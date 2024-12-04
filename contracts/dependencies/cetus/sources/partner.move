#[allow(lint(self_transfer))]
module cetus_clmm::partner {
    use sui::event;
    use sui::balance::{Balance};
    use sui::clock::{Clock};
    use sui::transfer::{transfer, share_object};
    use sui::tx_context::{sender};
    use sui::vec_map::{VecMap};
    
    public struct Partners has key {
        id: UID,
        partners: VecMap<std::string::String, ID>,
    }
    
    public struct PartnerCap has store, key {
        id: UID,
        name: std::string::String,
        partner_id: ID,
    }
    
    public struct Partner has store, key {
        id: UID,
        name: std::string::String,
        ref_fee_rate: u64,
        start_time: u64,
        end_time: u64,
        balances: sui::bag::Bag,
    }
    
    public struct InitPartnerEvent has copy, drop {
        partners_id: ID,
    }
    
    public struct CreatePartnerEvent has copy, drop {
        recipient: address,
        partner_id: ID,
        partner_cap_id: ID,
        ref_fee_rate: u64,
        name: std::string::String,
        start_time: u64,
        end_time: u64,
    }
    
    public struct UpdateRefFeeRateEvent has copy, drop {
        partner_id: ID,
        old_fee_rate: u64,
        new_fee_rate: u64,
    }
    
    public struct UpdateTimeRangeEvent has copy, drop {
        partner_id: ID,
        start_time: u64,
        end_time: u64,
    }
    
    public struct ReceiveRefFeeEvent has copy, drop {
        partner_id: ID,
        amount: u64,
        type_name: std::string::String,
    }
    
    public struct ClaimRefFeeEvent has copy, drop {
        partner_id: ID,
        amount: u64,
        type_name: std::string::String,
    }
    
    public fun balances(arg0: &Partner) : &sui::bag::Bag {
        &arg0.balances
    }
    
    public fun claim_ref_fee<T0>(arg0: &cetus_clmm::config::GlobalConfig, arg1: &PartnerCap, arg2: &mut Partner, arg3: &mut TxContext) {
        cetus_clmm::config::checked_package_version(arg0);
        assert!(arg1.partner_id == arg2.id.to_inner(), 4);
        let v0 = std::string::from_ascii(std::type_name::into_string(std::type_name::get<T0>()));
        assert!(sui::bag::contains<std::string::String>(&arg2.balances, v0), 5);
        let v1 = sui::bag::remove<std::string::String, Balance<T0>>(&mut arg2.balances, v0);
        let amount = sui::balance::value<T0>(&v1);
        sui::transfer::public_transfer<sui::coin::Coin<T0>>(sui::coin::from_balance<T0>(v1, arg3), sender(arg3));
        let v2 = ClaimRefFeeEvent{
            partner_id : arg2.id.to_inner(), 
            amount,
            type_name  : v0,
        };
        event::emit<ClaimRefFeeEvent>(v2);
    }
    
    public fun create_partner(arg0: &cetus_clmm::config::GlobalConfig, arg1: &mut Partners, arg2: std::string::String, arg3: u64, arg4: u64, arg5: u64, arg6: address, arg7: &Clock, arg8: &mut TxContext) {
        assert!(arg5 > arg4, 2);
        assert!(arg4 >= sui::clock::timestamp_ms(arg7) / 1000, 2);
        assert!(arg3 < 10000, 3);
        assert!(!std::string::is_empty(&arg2), 6);
        assert!(!sui::vec_map::contains<std::string::String, ID>(&arg1.partners, &arg2), 1);
        cetus_clmm::config::checked_package_version(arg0);
        cetus_clmm::config::check_partner_manager_role(arg0, sender(arg8));
        let v0 = Partner {
            id: sui::object::new(arg8), 
            name: arg2, 
            ref_fee_rate: arg3, 
            start_time: arg4, 
            end_time: arg5, 
            balances: sui::bag::new(arg8),
        };
        let v1 = PartnerCap {
            id         : sui::object::new(arg8), 
            name       : arg2, 
            partner_id : v0.id.to_inner(),
        };

        let partner_cap_id = v1.id.to_inner();
        let v2 = v0.id.to_inner();
        sui::vec_map::insert<std::string::String, ID>(&mut arg1.partners, arg2, v2);
        share_object<Partner>(v0);
        transfer<PartnerCap>(v1, arg6);
        let v3 = CreatePartnerEvent{
            recipient      : arg6, 
            partner_id     : v2, 
            partner_cap_id,
            ref_fee_rate   : arg3, 
            name           : arg2, 
            start_time     : arg4, 
            end_time       : arg5,
        };
        event::emit<CreatePartnerEvent>(v3);
    }
    
    public fun current_ref_fee_rate(arg0: &Partner, arg1: u64) : u64 {
        if (arg0.start_time > arg1 || arg0.end_time <= arg1) {
            return 0
        };
        arg0.ref_fee_rate
    }
    
    public fun end_time(arg0: &Partner) : u64 {
        arg0.end_time
    }
    
    fun init(arg0: &mut TxContext) {
        let v0 = Partners{
            id       : sui::object::new(arg0), 
            partners : sui::vec_map::empty<std::string::String, ID>(),
        };
        let partners_id = v0.id.to_inner();

        share_object<Partners>(v0);
        let v1 = InitPartnerEvent{ partners_id };
        event::emit<InitPartnerEvent>(v1);
    }
    
    public fun name(arg0: &Partner) : std::string::String {
        arg0.name
    }
    
    public fun receive_ref_fee<T0>(arg0: &mut Partner, arg1: Balance<T0>) {
        let amount = sui::balance::value<T0>(&arg1);
        let v0 = std::string::from_ascii(std::type_name::into_string(std::type_name::get<T0>()));
        if (sui::bag::contains<std::string::String>(&arg0.balances, v0)) {
            sui::balance::join<T0>(sui::bag::borrow_mut<std::string::String, Balance<T0>>(&mut arg0.balances, v0), arg1);
        } else {
            sui::bag::add<std::string::String, Balance<T0>>(&mut arg0.balances, v0, arg1);
        };
        let v1 = ReceiveRefFeeEvent{
            partner_id : arg0.id.to_inner(), 
            amount,
            type_name  : v0,
        };
        event::emit<ReceiveRefFeeEvent>(v1);
    }
    
    public fun ref_fee_rate(arg0: &Partner) : u64 {
        arg0.ref_fee_rate
    }
    
    public fun partner_id(arg0: &Partner) : ID {
        arg0.id.to_inner()
    }
    
    public fun partners_id(arg0: &Partners) : ID {
        arg0.id.to_inner()
    }
    
    public fun start_time(arg0: &Partner) : u64 {
        arg0.start_time
    }
    
    public fun update_ref_fee_rate(arg0: &cetus_clmm::config::GlobalConfig, arg1: &mut Partner, arg2: u64, arg3: &TxContext) {
        assert!(arg2 < 10000, 3);
        cetus_clmm::config::checked_package_version(arg0);
        cetus_clmm::config::check_partner_manager_role(arg0, sender(arg3));
        arg1.ref_fee_rate = arg2;
        let v0 = UpdateRefFeeRateEvent{
            partner_id   : arg1.id.to_inner(), 
            old_fee_rate : arg1.ref_fee_rate, 
            new_fee_rate : arg2,
        };
        event::emit<UpdateRefFeeRateEvent>(v0);
    }
    
    public fun update_time_range(arg0: &cetus_clmm::config::GlobalConfig, arg1: &mut Partner, arg2: u64, arg3: u64, arg4: &Clock, arg5: &mut TxContext) {
        assert!(arg3 > arg2, 2);
        assert!(arg3 > sui::clock::timestamp_ms(arg4) / 1000, 2);
        cetus_clmm::config::checked_package_version(arg0);
        cetus_clmm::config::check_partner_manager_role(arg0, sender(arg5));
        arg1.start_time = arg2;
        arg1.end_time = arg3;
        let v0 = UpdateTimeRangeEvent{
            partner_id : arg1.id.to_inner(), 
            start_time : arg2, 
            end_time   : arg3,
        };
        event::emit<UpdateTimeRangeEvent>(v0);
    }
    
    // decompiled from Move bytecode v6
}

