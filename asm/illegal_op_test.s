; illegal_op_test.s

    ldi r6, #0xFFFF
    ldi r0, #0x1234

    st [r6], r0     ; expect 0x1234

    nop
    nop

    .word 0xF800    ; illegal opcode 1F

    halt
