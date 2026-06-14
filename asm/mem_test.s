; mem_test.s -- LD/ST round-trip, no aliasing, output port

    ldi r6, #0xFFFF         ; output port

; smoke-test the port with a direct constant (before touching RAM)
    ldi r0, #0xF00D
    st [r6], r0             ; expect 0xF00D

; set up two (address, value) pairs
    ldi r2, #0x0040         ; addr1
    ldi r3, #0xBEEF         ; data1
    ldi r4, #0x0080         ; addr2
    ldi r5, #0xCAFE         ; data2

; store both, then load them back into different registers
    st [r2], r3             ; mem[0040] = BEEF
    st [r4], r5             ; mem[0080] = CAFE
    ld r0, [r2]             ; r0 = mem[0040]  (expect BEEF)
    ld r1, [r4]             ; r1 = mem[0080]  (expect CAFE; proves no aliasing)

; echo the round-tripped values
    st [r6], r0             ; expect 0xBEEF
    st [r6], r1             ; expect 0xCAFE

; done marker
    ldi r7, #0xEEEE
    st [r6], r7             ; expect 0xEEEE

    halt
