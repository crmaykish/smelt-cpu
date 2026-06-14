; call_test.s -- verify JSR (link register r7) and RTS.
;
; One subroutine is called from TWO different sites. The subroutine submits its
; own marker (0x00AA) -- proving JSR actually jumped to it -- and each call site
; submits a distinct marker afterward (0x0011, 0x0022) -- proving RTS returned to
; the RIGHT site, i.e. the return address JSR saved in r7 is actually used. A
; broken RTS (fixed target) would mis-order or drop these markers.
;
; r7 is the link register -- don't use it for data here. Single-level only;
; nesting would require saving/restoring r7.

        ldi r6, #0xFFFF        ; output port
        ldi r4, #0x00AA        ; "subroutine ran" marker

        jsr sub                ; --- call site 1 ---
        ldi r0, #0x0011        ; site-1 marker
        st  [r6], r0           ; expect 0x0011 (returned to site 1)

        jsr sub                ; --- call site 2 ---
        ldi r0, #0x0022        ; site-2 marker
        st  [r6], r0           ; expect 0x0022 (returned to site 2)

        halt

; subroutine: submit the "ran" marker, then return via r7
sub:
        st  [r6], r4           ; expect 0x00AA
        rts
