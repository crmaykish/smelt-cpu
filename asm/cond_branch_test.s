; cond_branch_test.s -- BEQ/BNE, taken and not-taken paths
; Each test submits a distinct marker on the correct path; a wrong branch
; submits the trap marker (0xDEAD) instead, failing the golden compare.
; Flags are asserted too -- they verify the cmp that drove each decision.

    ldi r6, #0xFFFF
    ldi r1, #0x1111
    ldi r2, #0x2222
    ldi r7, #0xDEAD         ; trap marker

; Test 1: BEQ taken (Z=1) -> must skip the trap
    cmp r1, r1
    beq t1ok
    st [r6], r7             ; TRAP
t1ok:
    ldi r0, #0x00E1
    st [r6], r0             ; expect 0x00E1  (Z=1 C=1 from cmp r1,r1)

; Test 2: BEQ not-taken (Z=0) -> must fall through
    cmp r1, r2
    beq t2trap
    jmp t2ok
t2trap:
    st [r6], r7             ; TRAP
t2ok:
    ldi r0, #0x00E2
    st [r6], r0             ; expect 0x00E2  (Z=0 C=0 from cmp r1,r2)

; Test 3: BNE taken (Z=0) -> must skip the trap
    cmp r1, r2
    bne t3ok
    st [r6], r7             ; TRAP
t3ok:
    ldi r0, #0x00E3
    st [r6], r0             ; expect 0x00E3  (Z=0 C=0)

; Test 4: BNE not-taken (Z=1) -> must fall through
    cmp r1, r1
    bne t4trap
    jmp t4ok
t4trap:
    st [r6], r7             ; TRAP
t4ok:
    ldi r0, #0x00E4
    st [r6], r0             ; expect 0x00E4  (Z=1 C=1)

    halt
