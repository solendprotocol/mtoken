module cetus_clmm::acl {
    use move_stl::linked_table::{LinkedTable};
    
    public struct ACL has store {
        permissions: LinkedTable<address, u128>,
    }
    
    public struct Member has copy, drop, store {
        address: address,
        permission: u128,
    }
    
    public fun new(arg0: &mut TxContext) : ACL {
        ACL{permissions: move_stl::linked_table::new<address, u128>(arg0)}
    }
    
    public fun add_role(arg0: &mut ACL, arg1: address, arg2: u8) {
        assert!(arg2 < 128, 0);
        if (move_stl::linked_table::contains<address, u128>(&arg0.permissions, arg1)) {
            let v0 = move_stl::linked_table::borrow_mut<address, u128>(&mut arg0.permissions, arg1);
            *v0 = *v0 | 1 << arg2;
        } else {
            move_stl::linked_table::push_back<address, u128>(&mut arg0.permissions, arg1, 1 << arg2);
        };
    }
    
    public fun get_members(arg0: &ACL) : vector<Member> {
        let mut v0 = std::vector::empty<Member>();
        let mut v1 = move_stl::linked_table::head<address, u128>(&arg0.permissions);
        while (std::option::is_some<address>(&v1)) {
            let v2 = *std::option::borrow<address>(&v1);
            let v3 = move_stl::linked_table::borrow_node<address, u128>(&arg0.permissions, v2);
            let v4 = Member{
                address    : v2, 
                permission : *move_stl::linked_table::borrow_value<address, u128>(v3),
            };
            std::vector::push_back<Member>(&mut v0, v4);
            v1 = move_stl::linked_table::next<address, u128>(v3);
        };
        v0
    }
    
    public fun get_permission(arg0: &ACL, arg1: address) : u128 {
        if (!move_stl::linked_table::contains<address, u128>(&arg0.permissions, arg1)) {
            0
        } else {
            *move_stl::linked_table::borrow<address, u128>(&arg0.permissions, arg1)
        }
    }
    
    public fun has_role(arg0: &ACL, arg1: address, arg2: u8) : bool {
        assert!(arg2 < 128, 0);
        move_stl::linked_table::contains<address, u128>(&arg0.permissions, arg1) && *move_stl::linked_table::borrow<address, u128>(&arg0.permissions, arg1) & 1 << arg2 > 0
    }
    
    public fun remove_member(arg0: &mut ACL, arg1: address) {
        if (move_stl::linked_table::contains<address, u128>(&arg0.permissions, arg1)) {
            move_stl::linked_table::remove<address, u128>(&mut arg0.permissions, arg1);
        };
    }
    
    public fun remove_role(arg0: &mut ACL, arg1: address, arg2: u8) {
        assert!(arg2 < 128, 0);
        if (move_stl::linked_table::contains<address, u128>(&arg0.permissions, arg1)) {
            let v0 = move_stl::linked_table::borrow_mut<address, u128>(&mut arg0.permissions, arg1);
            *v0 = *v0 - (1 << arg2);
        };
    }
    
    public fun set_roles(arg0: &mut ACL, arg1: address, arg2: u128) {
        if (move_stl::linked_table::contains<address, u128>(&arg0.permissions, arg1)) {
            *move_stl::linked_table::borrow_mut<address, u128>(&mut arg0.permissions, arg1) = arg2;
        } else {
            move_stl::linked_table::push_back<address, u128>(&mut arg0.permissions, arg1, arg2);
        };
    }
    
    // decompiled from Move bytecode v6
}

