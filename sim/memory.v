`timescale 1ns/1ps

// simulated memory for smelt_cpu.v test bench
module memory
(
    input  wire        clk,
    input  wire [15:0] addr,
    input  wire [15:0] wdata,
    input  wire        we,
    output reg [15:0] rdata
);

    localparam DEPTH = 1024;            // number of words (2KB total)
    localparam OUT_PORT = 16'hFFFF;     // Output port (MMIO address for the test bench)

    // Memory array
    reg [15:0] mem [0:DEPTH-1];

    // Load the test ROM code. The hex file is required, selected at run time:
    //   vvp sim/smelt.vvp +hex=asm/nop_test.hex
    reg [1023:0] hexfile;
    initial begin
        if (!$value$plusargs("hex=%s", hexfile)) begin
            $display("ERROR: no program given -- pass +hex=<file> (e.g. make sim HEX=...)");
            $finish;
        end
        $readmemh(hexfile, mem);
    end

    always @(posedge clk) begin
        if (we) begin
            if (addr == OUT_PORT) $display("OUT: %h", wdata);
            else mem[addr] <= wdata;
        end
        rdata <= mem[addr];
    end

endmodule
