-- Exhaustive test program for divide subprogram.
-- Results are checked as the computation progresses.
-- If error is found, halts after loading xffff in ACC.
-- Otherwise, just continues to run
--
-- i = 10;
-- while (true) {
--     for (j = 1; j <= i+1; j++) {
--          (q,r) = div(i,j);
--          if ((i == 0 && q != 0) ||
--              (i != mult(q,j) + r)) {
--	        acc = 0xffff; halt;
--          }
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
            -- TODO            --         (q,r) = div(i,j)
            dLoad i            --          if ((i == 0 && q != 0) ||
            brZero 2
            branch skip1
            dLoad q
            brZero 2
            branch oops
skip1:      -- TODO            --               (i != mult(q,j) + r)) {
oops:       cLoad -1           --              acc = 0xffff; halt;
            halt
skip3:      cLoad 1            --     }   }
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
q:          0
r:          0
