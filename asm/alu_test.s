; alu_test.s -- exercise every ALU op; submit r0 after each so the golden
; checks result + Z + C. The logic ops (and/or/xor) preserve C, so the C
; column also verifies the C-preservation chain seeded by the SUB at line ~6.

    ldi r6, #0xFFFF

; --- ADD: no carry, no zero ---
    ldi r0, #0x2222
    ldi r1, #0x3333
    add r0, r1
    st [r6], r0         ; expect 5555  Z=0 C=0

; --- ADD: zero result ---
    ldi r0, #0x0000
    add r0, r0
    st [r6], r0         ; expect 0000  Z=1 C=0

; --- ADD: carry out ---
    ldi r0, #0xF000
    ldi r1, #0x2000
    add r0, r1
    st [r6], r0         ; expect 1000  Z=0 C=1

; --- SUB: no borrow (rd >= rs) ---
    ldi r0, #0x3000
    ldi r1, #0x1000
    sub r0, r1
    st [r6], r0         ; expect 2000  Z=0 C=1

; --- SUB: borrow (rd < rs) ---
    ldi r0, #0x2000
    ldi r1, #0x3000
    sub r0, r1
    st [r6], r0         ; expect F000  Z=0 C=0

; --- SUB: zero, no borrow (rd == rs) ---  (this C=1 seeds the chain below)
    ldi r0, #0x1000
    sub r0, r0
    st [r6], r0         ; expect 0000  Z=1 C=1

; --- AND: nonzero result (C preserved = 1) ---
    ldi r0, #0xFF00
    ldi r1, #0x0FF0
    and r0, r1
    st [r6], r0         ; expect 0F00  Z=0 C=1

; --- AND: zero result (C preserved = 1) ---
    ldi r0, #0xFF00
    ldi r1, #0x00FF
    and r0, r1
    st [r6], r0         ; expect 0000  Z=1 C=1

; --- OR: nonzero result (C preserved = 1) ---
    ldi r0, #0xF000
    ldi r1, #0x000F
    or r0, r1
    st [r6], r0         ; expect F00F  Z=0 C=1

; --- OR: zero result (C preserved = 1) ---
    ldi r0, #0x0000
    ldi r1, #0x0000
    or r0, r1
    st [r6], r0         ; expect 0000  Z=1 C=1

; --- XOR: nonzero result (C preserved = 1) ---
    ldi r0, #0xFF00
    ldi r1, #0x0FF0
    xor r0, r1
    st [r6], r0         ; expect F0F0  Z=0 C=1

; --- XOR: zero result (C preserved = 1) ---
    ldi r0, #0xABCD
    xor r0, r0
    st [r6], r0         ; expect 0000  Z=1 C=1

; --- SHL: no carry out (bit15 = 0) ---
    ldi r0, #0x1234
    shl r0
    st [r6], r0         ; expect 2468  Z=0 C=0

; --- SHL: carry out, nonzero result ---
    ldi r0, #0xC000
    shl r0
    st [r6], r0         ; expect 8000  Z=0 C=1

; --- SHL: carry out, zero result ---
    ldi r0, #0x8000
    shl r0
    st [r6], r0         ; expect 0000  Z=1 C=1

; --- SHR: no carry out (bit0 = 0) ---
    ldi r0, #0x2468
    shr r0
    st [r6], r0         ; expect 1234  Z=0 C=0

; --- SHR: carry out, nonzero result ---
    ldi r0, #0x0003
    shr r0
    st [r6], r0         ; expect 0001  Z=0 C=1

; --- SHR: carry out, zero result ---
    ldi r0, #0x0001
    shr r0
    st [r6], r0         ; expect 0000  Z=1 C=1

; --- SHR: logical fill (MSB <- 0, no sign extension) ---
    ldi r0, #0x8000
    shr r0
    st [r6], r0         ; expect 4000  Z=0 C=0

; --- CMP: greater (rd > rs) -- r0 unchanged ---
    ldi r0, #0x5000
    ldi r1, #0x2000
    cmp r0, r1
    st [r6], r0         ; expect 5000  Z=0 C=1

; --- CMP: less (rd < rs) ---
    ldi r0, #0x2000
    ldi r1, #0x5000
    cmp r0, r1
    st [r6], r0         ; expect 2000  Z=0 C=0

; --- CMP: equal (rd == rs) ---
    ldi r0, #0x4000
    ldi r1, #0x4000
    cmp r0, r1
    st [r6], r0         ; expect 4000  Z=1 C=1

    halt
