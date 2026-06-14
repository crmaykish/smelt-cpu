; mov_test.s

    ldi r6, #0xFFFF
    ldi r0, #0
    ldi r1, #0xABCD

    st [r6], r0     ; expect 0, no flags

    cmp r1, r1      ; Set Z,C flags

    st [r6], r0     ; expect 0
    st [r6], r1     ; expect 0xABCD

    mov r0, r1

    st [r6], r0     ; expect 0xABCD in r0
    st [r6], r1     ; expect 0xABCD in r1

    halt
