; ldi_test.s -- load immediate into several registers, verify each value lands

    ldi r6, #0xFFFF

    ldi r0, #0x0000
    ldi r1, #0xABCD
    ldi r2, #0xFFFF
    ldi r3, #0x0001

    st [r6], r0     ; expect 0x0000
    st [r6], r1     ; expect 0xABCD
    st [r6], r2     ; expect 0xFFFF
    st [r6], r3     ; expect 0x0001

    halt
