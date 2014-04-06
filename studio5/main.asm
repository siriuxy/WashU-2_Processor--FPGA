-- Exhaustive test program for multiply subprogram.
--
-- i = 10;
-- while (true) {
--     for (j = 1; j <= i+1; j++) {
--          p = mult(i,j);
--      }
--      i++;
--      if (i < 0) i = 0;
-- }
--
            cLoad 10          -- i = 10;
            dStore i
loop1:      cLoad 1           -- while (true) {
            dStore j          --     for (j = 1; j <= i+1; j++) {
loop2:      cLoad 1
            add i
            negate
            add j
            brPos end2
            -- TODO            --         p = mult(i,j);
            cLoad 1            --     }
            add j
            dStore j
            branch loop2      
end2:       cLoad 1            --     i++;
            add i
            dStore i
            brNeg 2            --      if (i < 0) i = 0;
            branch 3
            cLoad 0
            dStore i
            branch loop1       -- }
            location 0f0
i:          0
j:          0
p:          0
