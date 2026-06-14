#   make test                                     assemble + run the whole suite
#   make sim HEX=asm/x.hex GOLDEN=asm/x.golden    run a specific program
#   make sim HEX=... GOLDEN=... EXPECT_ERROR=1    run a fault test (expects error)
#   make wave HEX=... GOLDEN=...                   run then open the VCD in gtkwave
#   make clean                                    remove build artifacts
#
# HEX is required for `sim`/`wave` (no built-in default); `test` assembles each
# asm/*.s itself.

IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

SRC = rtl/smelt_cpu.v rtl/smelt_alu.v sim/memory.v sim/tb_smelt.v
OUT = sim/smelt.vvp
VCD = sim/smelt.vcd

# Per-run program selection -- override on the command line, e.g.
#   make sim HEX=asm/branch_test.hex GOLDEN=asm/branch_test.golden
# Left empty, the testbench/memory fall back to their built-in defaults.
HEX ?=
GOLDEN ?=
EXPECT_ERROR ?=
PLUSARGS = $(if $(HEX),+hex=$(HEX)) $(if $(GOLDEN),+golden=$(GOLDEN)) $(if $(EXPECT_ERROR),+expect_error=$(EXPECT_ERROR))

.PHONY: sim test wave clean

sim: $(OUT)
	$(VVP) $(OUT) $(PLUSARGS)

# Assemble + run every asm/*.s against its golden; single green/red exit.
test: $(OUT)
	@./run_tests.sh

$(OUT): $(SRC)
	$(IVERILOG) -g2012 -Wall -I rtl -o $(OUT) $(SRC)

wave: sim
	$(GTKWAVE) $(VCD) &

clean:
	rm -f $(OUT) $(VCD)
