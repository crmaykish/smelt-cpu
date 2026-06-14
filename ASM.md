# Assembly Language Guide

A programmer's reference for writing Smelt assembly (`.s`) for `smeltasm`, the
two-pass assembler. This covers **syntax** - how to write source. For what each
instruction *does* (flags, carry convention, memory map), see [`ISA.md`](ISA.md).

```sh
smeltasm.py prog.s -o prog.hex     # assemble to a $readmemh-loadable .hex
smeltasm.py prog.s                 # ...or print the hex to stdout
```

---

## Source format

- **One statement per line.** A line may be blank, a comment, a label, an
  instruction, or a label followed by an instruction.
- **Case:** mnemonics and register names are case-insensitive (`ADD`, `add`,
  `Add` are equal). **Labels are case-sensitive** (`Loop` ≠ `loop`).
- **Whitespace** between tokens is free; indent however you like.
- Programs load at **address 0** and run from there. There is no `.org` in v1.

### Comments

Everything from a `;` to end of line is ignored.

```asm
        add  r0, r1      ; r0 = r0 + r1
; a full-line comment is fine too
```

### Labels

A name followed by `:` marks the current address. Use it as a branch target.
A label can sit on its own line or prefix an instruction:

```asm
loop:                    ; label on its own line
        sub  r0, r1
done:   halt             ; label + instruction on one line
```

Labels may be referenced **before** they're defined (forward branches) - the
assembler resolves them in a second pass.

---

## Operands

### Registers

Eight general registers, `r0`–`r7` (case-insensitive):

```asm
        mov  r2, r5
```

### Immediates

A literal value, written with a leading `#`. Three forms:

| Form        | Example     | Meaning            |
|-------------|-------------|--------------------|
| Hex         | `#0xFFFF`   | 65535              |
| Decimal     | `#42`       | 42                 |
| Negative    | `#-5`       | -5 (stored as two's complement `0xFFFB`) |

Immediates are only valid where an instruction expects one (currently `ldi`):

```asm
        ldi  r6, #0xFFFF     ; the output port address
        ldi  r0, #-1         ; 0xFFFF
```

### Memory operands

A register in **square brackets** means "the address held in that register":

```asm
        ld   r0, [r1]        ; load r0 from memory[r1]
        st   [r6], r0        ; store r0 to memory[r6]
```

---

## Instructions

Grouped by operand shape. (Semantics - which flags each sets, the no-borrow
carry convention - are in [`ISA.md`](ISA.md).)

### No operands

```asm
        nop
        halt
```

### `op  rd, rs` - register/register

`mov`, the arithmetic/logic ops, and `cmp` take a destination and a source
register:

```asm
        mov  r0, r1         ; r0 = r1
        add  r0, r1         ; r0 = r0 + r1
        sub  r0, r1
        and  r0, r1
        or   r0, r1
        xor  r0, r1
        cmp  r0, r1         ; flags only; r0 unchanged
```

### `op  rd` - shifts (single register)

`shl` and `shr` take **one** register and shift it by **one** bit (`rd ← rd <<
1` / `rd >> 1`). There is no variable shift amount - the second register field
is unused.

```asm
        shl  r0             ; r0 = r0 << 1   (LSB <- 0)
        shr  r0             ; r0 = r0 >> 1   (MSB <- 0, logical)
```

### `ldi  rd, #imm` - load immediate

The only **two-word** instruction: the opcode word plus the 16-bit value. It
occupies two memory slots, which the assembler accounts for automatically.

```asm
        ldi  r0, #0x1234
        ldi  r7, #100
```

### `ld` / `st` - memory

```asm
        ld   r0, [r1]       ; rd, [rs]  -> r0 = memory[r1]
        st   [r6], r0       ; [rd], rs  -> memory[r6] = r0
```

Storing to address `0xFFFF` writes the **output port** (prints `OUT: <val>` in
simulation) instead of RAM - the idiom the test harness uses to submit results:

```asm
        ldi  r6, #0xFFFF
        ldi  r0, #0x1234
        st   [r6], r0       ; submit 0x1234
```

### `jmp` / `beq` / `bne` - branches

The operand is a **label**. The assembler computes the PC-relative offset for
you:

```asm
        jmp  done           ; unconditional
        beq  done           ; branch if Z=1 (e.g. last cmp was equal)
        bne  loop           ; branch if Z=0
```

**Range limit:** the offset is a signed 8-bit value, so a branch can only reach
a target within **−128 … +127 words** of the instruction after it. Out-of-range
targets are a hard error (the assembler will not silently truncate). For longer
hops, branch to a nearby `jmp`, or restructure.

### `jsr` / `rts` - subroutines

`jsr` takes a **label** and is PC-relative (same ±127-word reach and rules as the
branches). It saves the return address into the link register **`r7`** and jumps;
`rts` takes no operand and returns by jumping to `r7`.

```asm
        jsr  delay          ; call: r7 = return address, then jump to `delay`
        ; ...
        rts                 ; return: jump to r7
```

`r7` is the link register, so don't keep data in it across a call. Calls are
**single-level**: a subroutine that itself calls another must save and restore
`r7` first (e.g. with `st`/`ld`) before nesting.

---

## Directives

### `.word`

Emit a raw 16-bit value into the program image - handy for data, tables, or
deliberately encoding a word with no mnemonic (e.g. an illegal opcode for a
fault test). Takes a bare literal (hex or decimal, **no** `#`):

```asm
        .word 0xF800        ; a raw illegal-opcode word
        .word 42
```

---

## A complete example

Count `r0` down from 5 to 0, submitting each value to the output port:

```asm
; countdown.s - emit 5,4,3,2,1 to the output port, then halt
        ldi  r6, #0xFFFF        ; output port address
        ldi  r0, #5             ; counter
        ldi  r1, #1             ; decrement step
        ldi  r2, #0             ; compare target

loop:   st   [r6], r0           ; submit current value
        sub  r0, r1             ; r0 -= 1   (sets Z when it hits 0)
        cmp  r0, r2             ; r0 == 0 ?
        bne  loop               ; not yet -> loop

        halt
```

---

## Quick reference

| Form                | Example            | Notes                         |
|---------------------|--------------------|-------------------------------|
| `;`                 | `add r0,r1 ; cmt`  | comment to end of line        |
| `label:`            | `loop:`            | branch target (case-sensitive)|
| `op`                | `nop`, `halt`      | no operands                   |
| `op rd, rs`         | `add r0, r1`       | register/register             |
| `op rd`             | `shl r0`, `shr r0` | single register (shift by one)|
| `ldi rd, #imm`      | `ldi r0, #0x1234`  | two words                     |
| `ld rd, [rs]`       | `ld r0, [r1]`      | load                          |
| `st [rd], rs`       | `st [r6], r0`      | store (`0xFFFF` = output port)|
| `jmp/beq/bne label` | `bne loop`         | offset ∈ [−128, 127] words    |
| `jsr label`         | `jsr delay`        | call; saves return in `r7`    |
| `rts`               | `rts`              | return (jump to `r7`)         |
| `.word EXPR`        | `.word 0xF800`     | raw 16-bit value              |
| immediate           | `#0x1F` `#42` `#-5`| hex / decimal / negative      |
| register            | `r0` … `r7`        | case-insensitive              |
