# Smelt CPU

Everyone who gets interested in FPGAs and programmable logic seems to inevitably drift into designing their own CPU. This is mine.

Smelt is a 16-bit, word-addressed von Neumann processor. It has eight 16-bit registers and a simple 5-bit opcode scheme. It is designed to be simple enough to understand and implement quickly, but one step above a toy in terms of complexity. This is primarily a learning exercise for me. There are plenty of similar projects online. I don't expect Smelt to be all that unique or to break any new ground in the amateur CPU architecture space.

This CPU design is simulation-focused, but the core should also be fully synthesizable on a real FPGA.

# Links
- [ISA Spec](ISA.md) - Instruction set documentation
- [Assembly Language Guide](ASM.md) - Guide to writing assembly for `smeltasm`

## Tools

- **iverilog** - simulation / testbench
- **gtkwave** - waveform visualization
