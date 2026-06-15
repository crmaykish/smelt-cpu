# Smelt CPU

Everyone who gets interested in FPGAs and programmable logic seems to inevitably drift into designing their own CPU. This is mine.

Smelt is a 16-bit, word-addressed von Neumann processor. It has eight 16-bit registers and a simple 5-bit opcode scheme. It is designed to be simple enough to understand and implement quickly, but one step above a toy in terms of complexity. This is primarily a learning exercise for me. There are plenty of similar projects online. I don't expect Smelt to be all that unique or to break any new ground in the amateur CPU architecture space.

This design is simulation-focused, but the core is plain synchronous Verilog with no vendor primitives, so it should be fully synthesizable. It would drop into a real FPGA with a small top-level wrapper (clock, reset, and a memory/peripheral interface).

## This Repo

- **`rtl/`** - the CPU core (`smelt_cpu.v`), a combinational ALU (`smelt_alu.v`), and the shared opcode table (`opcodes.vh`).
- **`tools/assembler/smeltasm.py`** - `smeltasm`, a tiny single-file Python assembler (`.s` → `.hex`).
- **`asm/`** - the test programs, each a `.s` source paired with a `.golden` expected-output file.
- **`sim/`** - the simulation memory model and the self-checking testbench.

## Building & testing

Everything is driven by `make` (simulation via [Icarus Verilog](http://iverilog.icarus.com/)). The whole regression suite runs in one command, with a single green/red result:

```sh
make test
```

This assembles every program in `asm/` with `smeltasm`, runs each through the testbench, and exits nonzero if any fail (so it's CI-friendly).

**How the tests check themselves.** Each program *submits* its results by storing to a memory-mapped output port at `0xFFFF`. The testbench compares that submit-stream, in order, against the program's `.golden` file - one row per submission, `RESULT Z C`, with `xxxx` meaning "don't care". (Flags are checked directly at the store, since carry isn't otherwise observable from software.) A run prints `ALL_PASS` or `FAILURES=N`.

To run or trace a single program, assemble it first, then point `make sim` at the hex + golden:

```sh
python3 tools/assembler/smeltasm.py asm/alu_test.s -o alu_test.hex
make sim  HEX=alu_test.hex GOLDEN=asm/alu_test.golden     # run it
make wave HEX=alu_test.hex GOLDEN=asm/alu_test.golden     # run + open the VCD in gtkwave
```

## Documentation

- [ISA Spec](ISA.md) - instruction set, encoding, flags, memory map.
- [Assembly Language Guide](ASM.md) - how to write programs for `smeltasm`.

## Tools

- **[Icarus Verilog](http://iverilog.icarus.com/)** (`iverilog` / `vvp`) - simulation / testbench
- **gtkwave** - waveform visualization
- **Python 3** - the `smeltasm` assembler (standard library only)
- **make** - build / test driver
