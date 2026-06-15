#!/usr/bin/env python3
"""smeltasm -- a tiny two-pass assembler for the Smelt ISA.

Usage:
    smeltasm.py input.s -o output.hex

Pipeline:  source -> parse -> pass 1 (build symbol table) -> pass 2 (encode)
           -> .hex words ($readmemh-compatible, one 16-bit word per line).

See README.md for the assembly language reference.
"""
import sys

# mnemonic -> (opcode, format)
ISA = {
    "nop":  (0x00, "none"),
    "halt": (0x01, "none"),
    "ldi":  (0x02, "imm"),   # rd, #imm   -> TWO words
    "mov":  (0x03, "rr"),
    "ld":   (0x04, "ld"),    # rd, [rs]
    "st":   (0x05, "st"),    # [rd], rs
    "add":  (0x06, "rr"),
    "sub":  (0x07, "rr"),
    "and":  (0x08, "rr"),
    "or":   (0x09, "rr"),
    "xor":  (0x0A, "rr"),
    "shl":  (0x0B, "r"),     # rd (shift by one; rs unused)
    "shr":  (0x0C, "r"),     # rd
    "cmp":  (0x0D, "rr"),
    "jmp":  (0x0E, "rel"),
    "beq":  (0x0F, "rel"),
    "bne":  (0x10, "rel"),
    "jsr":  (0x11, "rel"),   # PC-relative call; saves return addr in r7 (link)
    "rts":  (0x12, "none"),  # return: jump to r7
    "inc":  (0x13, "r"),     # rd <- rd + 1
    "dec":  (0x14, "r"),     # rd <- rd - 1
}

# Words emitted per instruction, by format. ldi is the only 2-word op; the
# pass-1 location counter must advance by this much per instruction.
FORMAT_SIZE = {
    "none": 1, "r": 1, "rr": 1, "ld": 1, "st": 1, "rel": 1, "imm": 2,
}


class AsmError(Exception):
    """An assembly error tied to a source line number (1-based)."""
    def __init__(self, lineno, msg):
        super().__init__(f"line {lineno}: {msg}")
        self.lineno = lineno


# Lexing

def parse_line(lineno, text):
    """Turn one raw source line into a statement dict (or None).

    A statement is {lineno, label, op, operands}:
      - label    : a 'name:' defined at this address, or None
      - op       : mnemonic (lowercased) or '.word', or None for a label-only line
      - operands : list of raw (un-parsed) operand tokens, original case kept
    Blank / comment-only lines return None.
    """
    code = text.split(";", 1)[0].strip()        # drop ';' comment, trim
    if not code:
        return None

    label = None
    if ":" in code:
        lbl, code = code.split(":", 1)
        label = lbl.strip()
        if not label.isidentifier():
            raise AsmError(lineno, f"invalid label '{label}'")
        code = code.strip()

    op = None
    operands = []
    if code:                                    # something after the optional label
        parts = code.split(None, 1)             # mnemonic, then the operand blob
        op = parts[0].lower()                   # mnemonics/directives are case-insensitive
        if len(parts) > 1:
            # split operands on commas; keep original case (labels are case-sensitive)
            operands = [o.strip() for o in parts[1].split(",")]

    return {"lineno": lineno, "label": label, "op": op, "operands": operands}


# Operand Helpers

def parse_int(lineno, s):
    """A signed integer literal: 0x.. hex, 0b.. binary, or decimal, with an
    optional leading +/-."""
    s = s.strip()
    body, neg = s, False
    if body.startswith("+"):
        body = body[1:]
    elif body.startswith("-"):
        body, neg = body[1:], True
    try:
        if body[:2].lower() == "0x":
            val = int(body, 16)
        elif body[:2].lower() == "0b":
            val = int(body, 2)
        else:
            val = int(body, 10)
    except (ValueError, IndexError):
        raise AsmError(lineno, f"invalid number '{s}'")
    return -val if neg else val


def parse_reg(lineno, tok):
    """'r0'..'r7' (case-insensitive) -> int 0..7."""
    t = tok.lower()
    if len(t) == 2 and t[0] == "r" and t[1] in "01234567":
        return int(t[1])
    raise AsmError(lineno, f"expected register r0-r7, got '{tok}'")


def parse_imm(lineno, tok):
    """A '#'-prefixed literal -> int (#0x.. / #.. / #-..)."""
    if not tok.startswith("#"):
        raise AsmError(lineno, f"expected immediate '#...', got '{tok}'")
    return parse_int(lineno, tok[1:])


def parse_mem(lineno, tok):
    """A '[rN]' memory operand -> the inner register number."""
    if tok.startswith("[") and tok.endswith("]"):
        return parse_reg(lineno, tok[1:-1].strip())
    raise AsmError(lineno, f"expected memory operand '[rN]', got '{tok}'")


def expect_nargs(stmt, n):
    """Assert an instruction got exactly n operands."""
    got = len(stmt["operands"])
    if got != n:
        raise AsmError(stmt["lineno"],
                       f"'{stmt['op']}' expects {n} operand(s), got {got}")


def stmt_size(stmt):
    """How many words this statement emits (for the pass-1 location counter)."""
    op = stmt["op"]
    if op == ".word":
        return 1
    if op not in ISA:
        raise AsmError(stmt["lineno"], f"unknown instruction '{op}'")
    return FORMAT_SIZE[ISA[op][1]]


# Pass 1 - Addresses and Symbol Table

def first_pass(statements):
    """Assign each statement an address, recording 'label:' -> address.

    Returns (symtab, placed): symtab maps label names to word addresses;
    `placed` is [(addr, stmt), ...] for every statement that emits words,
    ready for pass 2.
    """
    symtab = {}
    placed = []
    addr = 0
    for stmt in statements:
        if stmt["label"] is not None:
            if stmt["label"] in symtab:
                raise AsmError(stmt["lineno"], f"duplicate label '{stmt['label']}'")
            symtab[stmt["label"]] = addr
        if stmt["op"] is not None:
            placed.append((addr, stmt))
            addr += stmt_size(stmt)
    return symtab, placed


# Pass 2 - Encoding

def encode(stmt, addr, symtab):
    """Encode one statement into a list of one or two 16-bit words."""
    lineno = stmt["lineno"]
    op = stmt["op"]
    ops = stmt["operands"]

    if op == ".word":
        expect_nargs(stmt, 1)
        return [parse_int(lineno, ops[0]) & 0xFFFF]

    opcode, fmt = ISA[op]

    if fmt == "none":
        expect_nargs(stmt, 0)
        return [opcode << 11]

    if fmt == "r":                              # shl / shr rd  (shift by one)
        expect_nargs(stmt, 1)
        rd = parse_reg(lineno, ops[0])
        return [(opcode << 11) | (rd << 8)]

    if fmt == "rr":                             # mov / alu / cmp:  rd, rs
        expect_nargs(stmt, 2)
        rd = parse_reg(lineno, ops[0])
        rs = parse_reg(lineno, ops[1])
        return [(opcode << 11) | (rd << 8) | (rs << 5)]

    if fmt == "imm":                            # ldi rd, #imm  -> two words
        expect_nargs(stmt, 2)
        rd = parse_reg(lineno, ops[0])
        imm = parse_imm(lineno, ops[1])
        return [(opcode << 11) | (rd << 8), imm & 0xFFFF]

    if fmt == "ld":                             # ld rd, [rs]
        expect_nargs(stmt, 2)
        rd = parse_reg(lineno, ops[0])
        rs = parse_mem(lineno, ops[1])
        return [(opcode << 11) | (rd << 8) | (rs << 5)]

    if fmt == "st":                             # st [rd], rs
        expect_nargs(stmt, 2)
        rd = parse_mem(lineno, ops[0])
        rs = parse_reg(lineno, ops[1])
        return [(opcode << 11) | (rd << 8) | (rs << 5)]

    if fmt == "rel":                            # jmp / beq / bne  label
        expect_nargs(stmt, 1)
        target = ops[0]
        if target not in symtab:
            raise AsmError(lineno, f"unknown label '{target}'")
        # The core resolves branches against the already-incremented PC, so the
        # offset is measured from the *next* instruction (addr + 1).
        offset = symtab[target] - (addr + 1)
        if not (-128 <= offset <= 127):
            raise AsmError(lineno,
                           f"branch to '{target}' out of range: {offset} words "
                           f"(must be -128..127)")
        return [(opcode << 11) | (offset & 0xFF)]

    raise AsmError(lineno, f"unhandled format '{fmt}' for '{op}'")  # unreachable


# Driver

def assemble(source):
    """Full source text -> list of 16-bit ints."""
    statements = []
    for i, text in enumerate(source.splitlines(), start=1):
        stmt = parse_line(i, text)
        if stmt is not None:
            statements.append(stmt)

    symtab, placed = first_pass(statements)

    words = []
    for addr, stmt in placed:
        words.extend(encode(stmt, addr, symtab))
    return words


def write_hex(words, out):
    """Emit one 4-digit hex word per line ($readmemh-compatible)."""
    for w in words:
        out.write(f"{w & 0xFFFF:04X}\n")


def main(argv):
    # Minimal arg handling: smeltasm.py input.s [-o output.hex]
    if len(argv) < 2:
        print("usage: smeltasm.py input.s [-o output.hex]", file=sys.stderr)
        return 2
    in_path = argv[1]
    out_path = None
    if "-o" in argv:
        out_path = argv[argv.index("-o") + 1]

    with open(in_path) as f:
        source = f.read()

    try:
        words = assemble(source)
    except AsmError as e:
        print(f"{in_path}: {e}", file=sys.stderr)
        return 1

    out = open(out_path, "w") if out_path else sys.stdout
    try:
        write_hex(words, out)
    finally:
        if out_path:
            out.close()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
