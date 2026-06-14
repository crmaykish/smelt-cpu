; branch_test.s -- unconditional JMP: forward, backward, sign-extended offset

    ldi r6, #0xFFFF
    ldi r0, #0xAAAA     ; good marker
    ldi r7, #0xDEAD     ; trap marker (must never reach the port)

    jmp start           ; forward jump over the landing block
land:
    st [r6], r0         ; expect 0xAAAA  (reached via the backward jump)
    halt

start:
    jmp skip            ; forward jump skips the trap
    st [r6], r7         ; TRAP: only submitted if the forward jump failed
skip:
    jmp land            ; backward jump (negative, sign-extended offset)
