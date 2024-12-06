module move_stl::linked_table {
    use std::option::{Self, Option};

    struct LinkedTable<T0: copy + drop + store, phantom T1: store> has store, key {
        id: sui::object::UID,
        head: Option<T0>,
        tail: Option<T0>,
        size: u64,
    }
    
    struct Node<T0: copy + drop + store, T1: store> has store {
        prev: Option<T0>,
        next: Option<T0>,
        value: T1,
    }
    
    public fun contains<T0: copy + drop + store, T1: store>(arg0: &LinkedTable<T0, T1>, arg1: T0) : bool {
        sui::dynamic_field::exists_with_type<T0, Node<T0, T1>>(&arg0.id, arg1)
    }
    
    public fun borrow<T0: copy + drop + store, T1: store>(arg0: &LinkedTable<T0, T1>, arg1: T0) : &T1 {
        &sui::dynamic_field::borrow<T0, Node<T0, T1>>(&arg0.id, arg1).value
    }
    
    public fun borrow_mut<T0: copy + drop + store, T1: store>(arg0: &mut LinkedTable<T0, T1>, arg1: T0) : &mut T1 {
        &mut sui::dynamic_field::borrow_mut<T0, Node<T0, T1>>(&mut arg0.id, arg1).value
    }
    
    public fun destroy_empty<T0: copy + drop + store, T1: drop + store>(arg0: LinkedTable<T0, T1>) {
        let LinkedTable {
            id   : v0,
            head : _,
            tail : _,
            size : v3,
        } = arg0;
        assert!(v3 == 0, 0);
        sui::object::delete(v0);
    }
    
    public fun length<T0: copy + drop + store, T1: store>(arg0: &LinkedTable<T0, T1>) : u64 {
        arg0.size
    }
    
    public fun push_back<T0: copy + drop + store, T1: store>(arg0: &mut LinkedTable<T0, T1>, arg1: T0, arg2: T1) {
        let v0 = Node<T0, T1>{
            prev  : arg0.tail, 
            next  : option::none<T0>(), 
            value : arg2,
        };
        option::swap_or_fill<T0>(&mut arg0.tail, arg1);
        if (option::is_none<T0>(&arg0.head)) {
            option::swap_or_fill<T0>(&mut arg0.head, arg1);
        };
        if (option::is_some<T0>(&v0.prev)) {
            option::swap_or_fill<T0>(&mut borrow_mut_node<T0, T1>(arg0, *option::borrow<T0>(&v0.prev)).next, arg1);
        };
        sui::dynamic_field::add<T0, Node<T0, T1>>(&mut arg0.id, arg1, v0);
        arg0.size = arg0.size + 1;
    }
    
    public fun remove<T0: copy + drop + store, T1: store>(arg0: &mut LinkedTable<T0, T1>, arg1: T0) : T1 {
        let Node {
            prev  : v0,
            next  : v1,
            value : v2,
        } = sui::dynamic_field::remove<T0, Node<T0, T1>>(&mut arg0.id, arg1);
        let v3 = v1;
        let v4 = v0;
        arg0.size = arg0.size - 1;
        if (option::is_some<T0>(&v4)) {
            sui::dynamic_field::borrow_mut<T0, Node<T0, T1>>(&mut arg0.id, *option::borrow<T0>(&v4)).next = v3;
        };
        if (option::is_some<T0>(&v3)) {
            sui::dynamic_field::borrow_mut<T0, Node<T0, T1>>(&mut arg0.id, *option::borrow<T0>(&v3)).prev = v4;
        };
        if (option::borrow<T0>(&arg0.head) == &arg1) {
            arg0.head = v3;
        };
        if (option::borrow<T0>(&arg0.tail) == &arg1) {
            arg0.tail = v4;
        };
        v2
    }
    
    public fun new<T0: copy + drop + store, T1: store>(arg0: &mut sui::tx_context::TxContext) : LinkedTable<T0, T1> {
        LinkedTable<T0, T1>{
            id   : sui::object::new(arg0), 
            head : option::none<T0>(), 
            tail : option::none<T0>(), 
            size : 0,
        }
    }
    
    public fun borrow_mut_node<T0: copy + drop + store, T1: store>(arg0: &mut LinkedTable<T0, T1>, arg1: T0) : &mut Node<T0, T1> {
        sui::dynamic_field::borrow_mut<T0, Node<T0, T1>>(&mut arg0.id, arg1)
    }
    
    public fun borrow_mut_value<T0: copy + drop + store, T1: store>(arg0: &mut Node<T0, T1>) : &mut T1 {
        &mut arg0.value
    }
    
    public fun borrow_node<T0: copy + drop + store, T1: store>(arg0: &LinkedTable<T0, T1>, arg1: T0) : &Node<T0, T1> {
        sui::dynamic_field::borrow<T0, Node<T0, T1>>(&arg0.id, arg1)
    }
    
    public fun borrow_value<T0: copy + drop + store, T1: store>(arg0: &Node<T0, T1>) : &T1 {
        &arg0.value
    }
    
    public fun drop<T0: copy + drop + store, T1: store>(arg0: LinkedTable<T0, T1>) {
        let LinkedTable {
            id   : v0,
            head : _,
            tail : _,
            size : _,
        } = arg0;
        sui::object::delete(v0);
    }
    
    public fun head<T0: copy + drop + store, T1: store>(arg0: &LinkedTable<T0, T1>) : Option<T0> {
        arg0.head
    }
    
    public fun insert_after<T0: copy + drop + store, T1: store>(arg0: &mut LinkedTable<T0, T1>, arg1: T0, arg2: T0, arg3: T1) {
        let v0 = borrow_mut_node<T0, T1>(arg0, arg1);
        let v1 = Node<T0, T1>{
            prev  : option::some<T0>(arg1), 
            next  : v0.next, 
            value : arg3,
        };
        option::swap_or_fill<T0>(&mut v0.next, arg2);
        if (option::is_some<T0>(&v1.next)) {
            option::swap_or_fill<T0>(&mut borrow_mut_node<T0, T1>(arg0, *option::borrow<T0>(&v1.next)).prev, arg2);
        } else {
            option::swap_or_fill<T0>(&mut arg0.tail, arg2);
        };
        sui::dynamic_field::add<T0, Node<T0, T1>>(&mut arg0.id, arg2, v1);
        arg0.size = arg0.size + 1;
    }
    
    public fun insert_before<T0: copy + drop + store, T1: store>(arg0: &mut LinkedTable<T0, T1>, arg1: T0, arg2: T0, arg3: T1) {
        let v0 = borrow_mut_node<T0, T1>(arg0, arg1);
        let v1 = Node<T0, T1>{
            prev  : v0.prev, 
            next  : option::some<T0>(arg1), 
            value : arg3,
        };
        option::swap_or_fill<T0>(&mut v0.prev, arg2);
        if (option::is_some<T0>(&v1.prev)) {
            option::swap_or_fill<T0>(&mut borrow_mut_node<T0, T1>(arg0, *option::borrow<T0>(&v1.prev)).next, arg2);
        } else {
            option::swap_or_fill<T0>(&mut arg0.head, arg2);
        };
        sui::dynamic_field::add<T0, Node<T0, T1>>(&mut arg0.id, arg2, v1);
        arg0.size = arg0.size + 1;
    }
    
    public fun is_empty<T0: copy + drop + store, T1: store>(arg0: &LinkedTable<T0, T1>) : bool {
        arg0.size == 0
    }
    
    public fun next<T0: copy + drop + store, T1: store>(arg0: &Node<T0, T1>) : Option<T0> {
        arg0.next
    }
    
    public fun prev<T0: copy + drop + store, T1: store>(arg0: &Node<T0, T1>) : Option<T0> {
        arg0.prev
    }
    
    public fun push_front<T0: copy + drop + store, T1: store>(arg0: &mut LinkedTable<T0, T1>, arg1: T0, arg2: T1) {
        let v0 = Node<T0, T1>{
            prev  : option::none<T0>(), 
            next  : arg0.head, 
            value : arg2,
        };
        option::swap_or_fill<T0>(&mut arg0.head, arg1);
        if (option::is_none<T0>(&arg0.tail)) {
            option::swap_or_fill<T0>(&mut arg0.tail, arg1);
        };
        if (option::is_some<T0>(&v0.next)) {
            option::swap_or_fill<T0>(&mut borrow_mut_node<T0, T1>(arg0, *option::borrow<T0>(&v0.next)).prev, arg1);
        };
        sui::dynamic_field::add<T0, Node<T0, T1>>(&mut arg0.id, arg1, v0);
        arg0.size = arg0.size + 1;
    }
    
    public fun tail<T0: copy + drop + store, T1: store>(arg0: &LinkedTable<T0, T1>) : Option<T0> {
        arg0.tail
    }
    
    // decompiled from Move bytecode v6
}

