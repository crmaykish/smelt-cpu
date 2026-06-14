`timescale 1ns/1ps

// Top level testbench for smelt_cpu.v
module tb_smelt;

    reg         clk;
    reg         rst;
    wire [15:0] addr;
    wire [15:0] wdata;
    wire        we;
    wire [15:0] rdata;
    wire        halted;

    // Smelt CPU DUT
    smelt_cpu cpu (
        .clk(clk), .rst(rst),
        .addr(addr), .wdata(wdata), .we(we),
        .rdata(rdata), .halted(halted)
    );

    // Simulated memory
    memory mem (
        .clk(clk), .addr(addr), .wdata(wdata), .we(we),
        .rdata(rdata)
    );

    // Toggle the CPU clock (10ns period)
    initial begin
        clk = 1'b0;
        
        forever #5 clk = ~clk;
    end

    // Power-on reset
    initial begin
        rst = 1'b1;
        #28 rst = 1'b0;
    end

    // Dump waveform
    initial begin
        $dumpfile("sim/smelt.vcd");
        $dumpvars(0, tb_smelt);
    end

    // Current opcode for display output, only valid when the CPU is in the DECODE cycle
    wire [4:0] opcode = (cpu.state == cpu.DECODE) ? cpu.rdata[15:11] : 5'bx;

    // Print a per-cycle state of the CPU internals
    always @(posedge clk) begin
        $display("T=%0t RST=%0d PC=%h OP=%h IR=%h rd=%0d STATE=%0d | R0=%h, R1=%h", 
            $time, cpu.rst, cpu.pc, opcode, cpu.ir, cpu.ir[10:8], cpu.state, cpu.regs[0], cpu.regs[1]);
    end

    // Clean stop when the CPU halts
    always @(posedge clk) begin
        if (halted) begin
            $display("HALT");
            $finish;
        end
    end

    // Safety timeout -- never let a buggy core spin forever.
    initial begin
        $display("Timed out!");
        #200 $finish;
    end

endmodule
