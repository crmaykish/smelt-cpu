#   make sim    compile and run the testbench
#   make wave   run then open the VCD in gtkwave
#   make clean  remove build artifacts

IVERILOG ?= iverilog
VVP ?= vvp
GTKWAVE ?= gtkwave

SRC = rtl/smelt_cpu.v rtl/smelt_alu.v sim/memory.v sim/tb_smelt.v
OUT = sim/smelt.vvp
VCD = sim/smelt.vcd

.PHONY: sim wave clean

sim: $(OUT)
	$(VVP) $(OUT)

$(OUT): $(SRC)
	$(IVERILOG) -g2012 -Wall -I rtl -o $(OUT) $(SRC)

wave: sim
	$(GTKWAVE) $(VCD) &

clean:
	rm -f $(OUT) $(VCD)
