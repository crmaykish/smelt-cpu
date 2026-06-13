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

    // Print a per-cycle state of the CPU internals
    always @(posedge clk) begin
        $display("T=%0t RST=%0d PC=%h IR=%h STATE=%0d", $time, cpu.rst, cpu.pc, cpu.ir, cpu.state);
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
