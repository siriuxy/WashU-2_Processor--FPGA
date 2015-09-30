-- int mult(int a, int b) {
--     prod = 0; // initialize product
--     mask = 1; // mask to select bits of multiplier
--     while (mask != 0) {
--         if ((b & mask) != 0) // add next partial product
--             prod += a;
--         a <<= 1;             // shift multiplicand
--         mask <<= 1;          // shift mask bit
--     }
--     return prod;
-- }
           location 0200
mult_a:    0                    -- first argument
mult_b:    0                    -- second argument
mult_prod: 0                    -- return value
mult_ret:  0                    -- return address
mult:      cLoad 0              -- prod = 0;
           dStore mult_prod
           cLoad 1              -- mask = 1;   
           dStore mult_mask
mult_loop: dLoad mult_mask      -- while (mask != 0) {
           brZero mult_end
           dLoad mult_b         --     if ((b & mask) != 0) 
           and mult_mask    
           brZero 4
           dLoad mult_prod      --          prod += a;
           add mult_a
           dStore mult_prod
           dLoad mult_a         --     a <<= 1;    
           lShift
           dStore mult_a
           dLoad mult_mask      --     mask <<= 1;
           lShift
           dStore mult_mask
           branch mult_loop     -- }
mult_end:  iBranch mult_ret     -- return prod;
           location 02f0
mult_mask: 0                    -- mask
