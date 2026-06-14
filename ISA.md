# Smelt ISA

The instruction set for Smelt, a tiny custom 16-bit CPU built from scratch in Verilog.

## 1. Machine Model

- **Data width:** 16 bits. Registers and the ALU are 16-bit.
- **Registers:** eight general-purpose 16-bit registers, `R0`–`R7`.
- **Program counter:** `PC`, 16-bit, points at the next instruction *word* to
  fetch. Starts at `0x0000` on reset.
- **Flags:** `Z` (zero) and `C` (carry). Set by ALU operations only.
- **Memory:** a single unified (von Neumann) memory, word-addressed

### Memory Map

| Address | Use |
|-|-|
| `0x0000` - `0xFFFE` | Program and data storage |
| `0xFFFF` | Hardcoded output port - writes to this port are printed out by the testbench |

### Reset

On reset, the `PC` register and `Z` and `C` flags go to `0`. Execution begins at `0x0000`.

### Halt

`HALT` stops the machine. The CPU stops the fetch-decode-execute loop entirely. This will also end the simulation testbench.

## 2. Instruction Encoding

Every instruction is a 16-bit word. The top 5 bits are the opcode, for a total of 32 possible opcodes.

There are three types of instructions: `R`egister, `I`mmediate, and `B`ranching.

| Type | Opcode | Operand 1 | Operand 2 | Immediate |
|-|-|-|-|-|
|R | opcode[15:11] | rd[10:8] | rs[7:5] |- |
|I | opcode[15:11] | rd[10:8] | - | next word |
|B | opcode[15:11] | - | offset[7:0] | - |

## 3. Instruction Set

`rd` and `rs` denote destination and source registers respectively. `mem[a]` is the memory value at `a` (16-bit).

The flags column lists flags which are impacted by the instruction. Unlisted flags are not impacted.

Smelt uses the no-borrow carry flag convention: `C=1` after `SUB` means no-borrow, i.e. `rd >= rs`.

| Opcode | Mnemonic        | Type | Operation                         | Flags |
|--------|-----------------|------|-----------------------------------|-------|
| `0x00` | `NOP`           |      | do nothing                        |       |
| `0x01` | `HALT`          |      | stop the CPU                      |       |
| `0x02` | `LDI rd, #imm`  |  I   | `rd ← imm16` (2-word)             |       |
| `0x03` | `MOV rd, rs`    |  R   | `rd ← rs`                         |       |
| `0x04` | `LD rd, [rs]`   |  R   | `rd ← mem[rs]`                    |       |
| `0x05` | `ST [rd], rs`   |  R   | `mem[rd] ← rs`                    |       |
| `0x06` | `ADD rd, rs`    |  R   | `rd ← rd + rs`                    | Z, C  |
| `0x07` | `SUB rd, rs`    |  R   | `rd ← rd - rs`                    | Z, C  |
| `0x08` | `AND rd, rs`    |  R   | `rd ← rd & rs`                    | Z     |
| `0x09` | `OR  rd, rs`    |  R   | `rd ← rd \| rs`                   | Z     |
| `0x0A` | `XOR rd, rs`    |  R   | `rd ← rd ^ rs`                    | Z     |
| `0x0B` | `SHL rd`        |  R   | `rd ← rd << 1` (LSB←0)            | Z, C  |
| `0x0C` | `SHR rd`        |  R   | `rd ← rd >> 1` (MSB←0, logical)   | Z, C  |
| `0x0D` | `CMP rd, rs`    |  R   | `rd - rs`, set flags only         | Z, C  |
| `0x0E` | `JMP rel`       |  B   | `PC ← PC + offset`                |       |
| `0x0F` | `BEQ rel`       |  B   | if `Z=1`: `PC ← PC + offset`      |       |
| `0x10` | `BNE rel`       |  B   | if `Z=0`: `PC ← PC + offset`      |       |
| `0x11` | `JSR rel`       |  B   | `R7 ← PC; PC ← PC + offset` (call) |      |
| `0x12` | `RTS`           |      | `PC ← R7` (return)                |       |

## 4. Branch & Subroutine Semantics

Branches (and `JSR`) are PC-relative. The reference point is the already-incremented `PC`, i.e. the address of the instruction that follows the branch word.

`offset` is a signed 8-bit count of words (range -128…+127). Counting is in words.

**Subroutines.** `R7` is the **link register**. `JSR rel` saves the return address - the already-incremented `PC`, i.e. the instruction after the `JSR` - into `R7`, then jumps PC-relative just like a branch. `RTS` returns by loading `PC` from `R7`. Calls do **not** nest automatically: a subroutine that calls another must first save and restore `R7` (e.g. to memory).

## 5. Program Format

Manually-assembled programs are stored as `.hex` files: one 16-bit value per line in hexadecimal, in ascending address order starting at `0x0000`. The testbench loads them into memory with Verilog's `$readmemh` command.

Assembly source code support (`.s` files) and a simple cross-assembler to follow.
