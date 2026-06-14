; NOP Instruction Test

    ldi r6, #0xFFFF
    ldi r0, #0x1234
    
    st [r6], r0     ; expect 0x1234

    nop
    nop

    st [r6], r0     ; expect 0x1234

    halt
