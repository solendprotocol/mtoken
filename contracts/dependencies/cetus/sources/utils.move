module cetus_clmm::utils {
    public fun str(mut  arg0: u64) : std::string::String {
        if (arg0 == 0) {
            return std::string::utf8(b"0")
        };
        let mut  v0 = std::vector::empty<u8>();
        while (arg0 > 0) {
            let v1 = ((arg0 % 10) as u8);
            arg0 = arg0 / 10;
            std::vector::push_back<u8>(&mut v0, v1 + 48);
        };
        std::vector::reverse<u8>(&mut v0);
        std::string::utf8(v0)
    }
    
    // decompiled from Move bytecode v6
}

