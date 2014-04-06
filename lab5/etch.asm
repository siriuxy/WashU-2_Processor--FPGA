-- Etch-a-sketch application
--
-- Entered via an interrupt that is triggered when a new data
-- value has been written to memory.
--
-- Examine M[03f0] which specifies a pixel in the display buffer.
-- The top byte specifies the x-coordinate of the pixel,
-- the bottom byte specifies the y-coordinate.
-- Make the specified pixel white.
--
-- y = pixel & 0ff;  -- pixel = M[03f0]
-- if (y > 119) y = 0;
-- x = pixel >> 8;
-- if (x > 159) x = 0;
-- q = x/5; r = x mod 5;
-- p = 0f000 + 32*y + q;
-- if (r == 0) *p = *p | x7000;
-- if (r == 1) *p = *p | x0e00;
-- if (r == 2) *p = *p | x01c0;
-- if (r == 3) *p = *p | x0038;
-- if (r == 4) *p = *p | x0007;
--
-- 
-- Then return from interrupt
            location 0300
etch:       cLoad 0ff               -- y = pixel & 0ff
            and etch_pix
            dStore etch_y
            cLoad 119               -- if (y > 119) y = 0;
            negate
            add etch_y
            brPos 2
            branch 3
            cLoad 0
            dStore etch_y
            dLoad etch_pix          -- x = pixel >> 8
            rShift
            rShift
            rShift
            rShift
            rShift
            rShift
            rShift
            rShift
            dStore etch_x           
            cLoad 159               -- if (x > 159) x = 0;
            negate
            add etch_x
            brPos 2
            branch 3
            cLoad 0
            dStore etch_x
            -- TODO                 -- q = x/5; r = x mod 5;
                                    -- p = 0f000 + 32*y + q;
                                    -- if (r == 0) *p = *p | x7000;
                                    -- if (r == 1) *p = *p | x0e00;
                                    -- if (r == 2) *p = *p | x01c0;
                                    -- if (r == 3) *p = *p | x0038;
                                    -- if (r == 4) *p = *p | x0007;
                                    -- return from interrupt
            location 03f0
etch_pix:   0                         -- location changed by user
etch_x:     0                         -- x-coordinate
etch_y:     0                         -- y coordinate
etch_p:     0                         -- pointer to x,y pixel
etch_q:     0                         -- q = x/5
etch_r:     0                         -- q = x mod 5
etch_m0:    07000                     -- mask for first pixel in word
etch_m1:    00e00                     -- mask for second pixel in word
etch_m2:    001c0                     -- mask for third pixel in word
etch_m3:    00038                     -- mask for fourth pixel in word
etch_m4:    00007                     -- mask for fifth pixel in word
etch_f000:  0f000                     -- first address in display buffer
