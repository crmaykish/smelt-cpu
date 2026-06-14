`timescale 1ns/1ps

// simulated memory for smelt_cpu.v test bench
module memory
(
    input  wire        clk,
    input  wire [15:0] addr,
    input  wire [15:0] wdata,
    input  wire        we,
    output wire [15:0] rdata
);

    localparam DEPTH = 1024;            // number of words (2KB total)
    localparam OUT_PORT = 16'hFFFF;     // Output port (MMIO address for the test bench)

    // Memory array
    reg [15:0] mem [0:DEPTH-1];

    // Load the test ROM code
    initial begin
        $readmemh("asm/add_test.hex", mem);
    end

    // Drive read-data from the current CPU address
    assign rdata = mem[addr];

endmodule
