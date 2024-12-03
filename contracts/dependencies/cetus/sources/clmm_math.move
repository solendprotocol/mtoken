module cetus_clmm::clmm_math {
    use integer_mate::i32::{I32};
    
    public fun compute_swap_step(arg0: u128, arg1: u128, arg2: u128, arg3: u64, arg4: u64, arg5: bool, arg6: bool) : (u64, u64, u128, u64) {
        if (arg2 == 0) {
            return (0, 0, arg1, 0)
        };
        if (arg5) {
            assert!(arg0 >= arg1, 4);
        } else {
            assert!(arg0 < arg1, 4);
        };
        let (v0, v1, v2, v3) = if (arg6) {
            let v4 = integer_mate::full_math_u64::mul_div_floor(arg3, 1000000 - arg4, 1000000);
            let v5 = get_delta_up_from_input(arg0, arg1, arg2, arg5);
            let (v0, v2, v3) = if (v5 > (v4 as u256)) {
                (v4, arg3 - v4, get_next_sqrt_price_from_input(arg0, arg2, v4, arg5))
            } else {
                let v6 = (v5 as u64);
                (v6, integer_mate::full_math_u64::mul_div_ceil(v6, arg4, 1000000 - arg4), arg1)
            };
            (v0, (get_delta_down_from_output(arg0, v3, arg2, arg5) as u64), v2, v3)
        } else {
            let v7 = get_delta_down_from_output(arg0, arg1, arg2, arg5);
            let (v1, v3) = if (v7 > (arg3 as u256)) {
                (arg3, get_next_sqrt_price_from_output(arg0, arg2, arg3, arg5))
            } else {
                ((v7 as u64), arg1)
            };
            let v8 = (get_delta_up_from_input(arg0, v3, arg2, arg5) as u64);
            (v8, v1, integer_mate::full_math_u64::mul_div_ceil(v8, arg4, 1000000 - arg4), v3)
        };
        (v0, v1, v3, v2)
    }
    
    public fun fee_rate_denominator() : u64 {
        1000000
    }
    
    public fun get_amount_by_liquidity(arg0: I32, arg1: I32, arg2: I32, arg3: u128, arg4: u128, arg5: bool) : (u64, u64) {
        if (arg4 == 0) {
            return (0, 0)
        };
        if (integer_mate::i32::lt(arg2, arg0)) {
            (get_delta_a(cetus_clmm::tick_math::get_sqrt_price_at_tick(arg0), cetus_clmm::tick_math::get_sqrt_price_at_tick(arg1), arg4, arg5), 0)
        } else {
            let (v2, v3) = if (integer_mate::i32::lt(arg2, arg1)) {
                (get_delta_a(arg3, cetus_clmm::tick_math::get_sqrt_price_at_tick(arg1), arg4, arg5), get_delta_b(cetus_clmm::tick_math::get_sqrt_price_at_tick(arg0), arg3, arg4, arg5))
            } else {
                (0, get_delta_b(cetus_clmm::tick_math::get_sqrt_price_at_tick(arg0), cetus_clmm::tick_math::get_sqrt_price_at_tick(arg1), arg4, arg5))
            };
            (v2, v3)
        }
    }
    
    public fun get_delta_a(arg0: u128, arg1: u128, arg2: u128, arg3: bool) : u64 {
        let v0 = if (arg0 > arg1) {
            arg0 - arg1
        } else {
            arg1 - arg0
        };
        if (v0 == 0 || arg2 == 0) {
            return 0
        };
        let (v1, v2) = integer_mate::math_u256::checked_shlw(integer_mate::full_math_u128::full_mul(arg2, v0));
        if (v2) {
            abort 2
        };
        (integer_mate::math_u256::div_round(v1, integer_mate::full_math_u128::full_mul(arg0, arg1), arg3) as u64)
    }
    
    public fun get_delta_b(arg0: u128, arg1: u128, arg2: u128, arg3: bool) : u64 {
        let v0 = if (arg0 > arg1) {
            arg0 - arg1
        } else {
            arg1 - arg0
        };
        if (v0 == 0 || arg2 == 0) {
            return 0
        };
        let v1 = integer_mate::full_math_u128::full_mul(arg2, v0);
        if (arg3 && v1 & 18446744073709551615 > 0) {
            return (((v1 >> 64) + 1) as u64)
        };
        ((v1 >> 64) as u64)
    }
    
    public fun get_delta_down_from_output(arg0: u128, arg1: u128, arg2: u128, arg3: bool) : u256 {
        let v0 = if (arg0 > arg1) {
            arg0 - arg1
        } else {
            arg1 - arg0
        };
        if (v0 == 0 || arg2 == 0) {
            return 0
        };
        if (arg3) {
            integer_mate::full_math_u128::full_mul(arg2, v0) >> 64
        } else {
            let (v2, v3) = integer_mate::math_u256::checked_shlw(integer_mate::full_math_u128::full_mul(arg2, v0));
            if (v3) {
                abort 2
            };
            integer_mate::math_u256::div_round(v2, integer_mate::full_math_u128::full_mul(arg0, arg1), false)
        }
    }
    
    public fun get_delta_up_from_input(arg0: u128, arg1: u128, arg2: u128, arg3: bool) : u256 {
        let v0 = if (arg0 > arg1) {
            arg0 - arg1
        } else {
            arg1 - arg0
        };
        if (v0 == 0 || arg2 == 0) {
            return 0
        };
        if (arg3) {
            let (v2, v3) = integer_mate::math_u256::checked_shlw(integer_mate::full_math_u128::full_mul(arg2, v0));
            if (v3) {
                abort 2
            };
            integer_mate::math_u256::div_round(v2, integer_mate::full_math_u128::full_mul(arg0, arg1), true)
        } else {
            let v4 = integer_mate::full_math_u128::full_mul(arg2, v0);
            if (v4 & 18446744073709551615 > 0) {
                return (v4 >> 64) + 1
            };
            v4 >> 64
        }
    }
    
    public fun get_liquidity_by_amount(tick_lower: I32, tick_upper: I32, current_tick_index: I32, current_sqrt_price: u128, amount: u64, from_a: bool) : (u128, u64, u64) {
        let mut amount_a = 0;
        let mut amount_b = 0;
        let liquidity_delta = if (from_a) {
            amount_a = amount;
            if (integer_mate::i32::lt(current_tick_index, tick_lower)) {
                get_liquidity_from_a(cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_lower), cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_upper), amount, false)
            } else {
                assert!(integer_mate::i32::lt(current_tick_index, tick_upper), 3018);
                let liquidity_delta = get_liquidity_from_a(current_sqrt_price, cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_upper), amount, false);
                amount_b = get_delta_b(current_sqrt_price, cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_lower), liquidity_delta, true);
                liquidity_delta
            }
        } else {
            amount_b = amount;
            if (integer_mate::i32::gte(current_tick_index, tick_upper)) {
                get_liquidity_from_b(cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_lower), cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_upper), amount, false)
            } else {
                assert!(integer_mate::i32::gte(current_tick_index, tick_lower), 3018);
                let liquidity_delta = get_liquidity_from_b(cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_lower), current_sqrt_price, amount, false);
                amount_a = get_delta_a(current_sqrt_price, cetus_clmm::tick_math::get_sqrt_price_at_tick(tick_upper), liquidity_delta, true);
                liquidity_delta
            }
        };
        (liquidity_delta, amount_a, amount_b)
        // (v2, v0, v1)
    }
    
    public fun get_liquidity_from_a(arg0: u128, arg1: u128, arg2: u64, arg3: bool) : u128 {
        let v0 = if (arg0 > arg1) {
            arg0 - arg1
        } else {
            arg1 - arg0
        };
        (integer_mate::math_u256::div_round((integer_mate::full_math_u128::full_mul(arg0, arg1) >> 64) * (arg2 as u256), (v0 as u256), arg3) as u128)
    }
    
    public fun get_liquidity_from_b(arg0: u128, arg1: u128, arg2: u64, arg3: bool) : u128 {
        let v0 = if (arg0 > arg1) {
            arg0 - arg1
        } else {
            arg1 - arg0
        };
        (integer_mate::math_u256::div_round((arg2 as u256) << 64, (v0 as u256), arg3) as u128)
    }
    
    public fun get_next_sqrt_price_a_up(arg0: u128, arg1: u128, arg2: u64, arg3: bool) : u128 {
        if (arg2 == 0) {
            return arg0
        };
        let (v0, v1) = integer_mate::math_u256::checked_shlw(integer_mate::full_math_u128::full_mul(arg0, arg1));
        if (v1) {
            abort 2
        };
        let v2 = if (arg3) {
            (integer_mate::math_u256::div_round(v0, ((arg1 as u256) << 64) + integer_mate::full_math_u128::full_mul(arg0, (arg2 as u128)), true) as u128)
        } else {
            (integer_mate::math_u256::div_round(v0, ((arg1 as u256) << 64) - integer_mate::full_math_u128::full_mul(arg0, (arg2 as u128)), true) as u128)
        };
        if (v2 > cetus_clmm::tick_math::max_sqrt_price()) {
            abort 0
        };
        if (v2 < cetus_clmm::tick_math::min_sqrt_price()) {
            abort 1
        };
        v2
    }
    
    public fun get_next_sqrt_price_b_down(arg0: u128, arg1: u128, arg2: u64, arg3: bool) : u128 {
        let v0 = if (arg3) {
            arg0 + integer_mate::math_u128::checked_div_round((arg2 as u128) << 64, arg1, !arg3)
        } else {
            arg0 - integer_mate::math_u128::checked_div_round((arg2 as u128) << 64, arg1, !arg3)
        };
        if (v0 > cetus_clmm::tick_math::max_sqrt_price()) {
            abort 0
        };
        if (v0 < cetus_clmm::tick_math::min_sqrt_price()) {
            abort 1
        };
        v0
    }
    
    public fun get_next_sqrt_price_from_input(arg0: u128, arg1: u128, arg2: u64, arg3: bool) : u128 {
        if (arg3) {
            get_next_sqrt_price_a_up(arg0, arg1, arg2, true)
        } else {
            get_next_sqrt_price_b_down(arg0, arg1, arg2, true)
        }
    }
    
    public fun get_next_sqrt_price_from_output(arg0: u128, arg1: u128, arg2: u64, arg3: bool) : u128 {
        if (arg3) {
            get_next_sqrt_price_b_down(arg0, arg1, arg2, false)
        } else {
            get_next_sqrt_price_a_up(arg0, arg1, arg2, false)
        }
    }
    
    // decompiled from Move bytecode v6
}

