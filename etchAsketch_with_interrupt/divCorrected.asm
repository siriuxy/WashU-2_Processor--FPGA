-- Division subroutine for washu-2
-- for non-negative numbers only
-- 
-- div(x,y) {
--     if (x < 0 || y <= 0) halt;
--     if (x == 0) return (0,y)
--     i = 0;
--     while (y < x && y&x4000 == 0)
--         y = y << 1; i++;
--     r = x; q = 0;
--     while (true) {
--         if (r >= y) {
--             q = q + 1;
--             r = r - y;
--         }
--         if (i == 0) break;
--         y = y >> 1;
--         q = q << 1;
--         i--;
--     }
--     return(q,r);
-- }
--
            location 0100
div_x:      0                     -- first argument
div_y:      0                     -- second argument
div_q:      0                     -- quotient (and returned value)
div_r:      0                     -- quotient (and returned value)
div_ret:    0                     -- return address
div:        dLoad div_x           --     if (x < 0 || y <= 0) halt;
            brNeg 3
            dLoad div_y
            brPos 2
            halt
            dLoad div_x           --     if (x == 0) return (0,y)
            brZero 2
            branch div_skip1
            cLoad 0
            dStore div_q
            dLoad div_y
            dStore div_r
            iBranch div_ret
div_skip1:  cLoad 0               --     i = 0;
            dStore div_i
            -- TODO               --     while (y < x && y&x4000 == 0) {
                                  --         y = y << 1;
                                  --         i++;
                                  --     }
                                  --     q = 0; r = x;
                                  --     while (true) {
                                  --        if (r >= y) {
                                  --             r = r - y;
                                  --             q = q + 1;
                                  --         }
                                  --         if (i == 0) break;
                                  --          y = y >> 1;
                                  --         q = q << 1;
                                  --         i--;
                                  --     } 
                                  --     return (q,r);
            location 01f0         -- }
div_i:      0
div_4000:   04000                
