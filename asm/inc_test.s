; inc_test.s -- verify INC (rd+1) and DEC (rd-1): result + Z + C, plus the
; dec/bne countdown idiom. Carry follows the ADD/SUB convention: INC sets C on
; carry-out (FFFF+1), DEC sets C = no-borrow (a >= 1). Countdown rows leave
; flags don't-care (incidental).

        ldi r6, #0xFFFF        ; output port

; --- INC: normal ---
        ldi r0, #0x1234
        inc r0
        st  [r6], r0           ; expect 0x1235  Z=0

; --- INC: wrap to zero ---
        ldi r0, #0xFFFF
        inc r0
        st  [r6], r0           ; expect 0x0000  Z=1

; --- DEC: normal ---
        ldi r0, #0x1234
        dec r0
        st  [r6], r0           ; expect 0x1233  Z=0

; --- DEC: to zero ---
        ldi r0, #0x0001
        dec r0
        st  [r6], r0           ; expect 0x0000  Z=1

; --- DEC: underflow ---
        ldi r0, #0x0000
        dec r0
        st  [r6], r0           ; expect 0xFFFF  Z=0

; --- dec/bne countdown idiom: should submit 3, 2, 1 then fall through ---
        ldi r0, #0x0003
loop:   st  [r6], r0
        dec r0
        bne loop

        halt
