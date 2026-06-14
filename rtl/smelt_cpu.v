`timescale 1ns/1ps

// 16-bit data, eight 16-bit registers, von Neumann architecture
module smelt_cpu (
    input clk,                  // CPU clock
    input rst,                  // Reset line
    input [15:0] rdata,         // Data read from memory
    output reg [15:0] addr,     // External address bus
    output reg [15:0] wdata,    // Data to write
    output reg we,              // Write-enable
    output reg halted           // CPU is halted
);

    // Opcode Definitions
    localparam NOP  = 16'h00;
    localparam HALT = 16'h01;
    localparam LDI  = 16'h02;

    // FSM States
    localparam FETCH    = 2'b00;
    localparam DECODE   = 2'b01;
    localparam EXEC     = 2'b10;
    localparam MEM      = 2'b11;   // extra memory access for LDI

    // CPU Cycle State
    reg [1:0] state = FETCH;

    // CPU Registers
    reg [15:0] pc = 16'b0;  // Program counter register
    reg [15:0] ir = 16'b0;  // Instruction register
    reg [15:0] regs [0:7];  // Data registers (R0 - R7)

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            addr    <= 16'h0000;
            wdata   <= 16'h0000;
            we      <= 1'b0;
            halted  <= 1'b0;
            pc      <= 16'b0;
            ir      <= 16'b0;
            state   <= FETCH;
        end else begin
            // Main fetch-decode-execute loop
            case (state)
                FETCH: begin
                    // TODO: could this address read be combinational?
                    addr <= pc;
                    state <= DECODE;
                end
                DECODE: begin
                    // Latch the incoming instruction
                    ir <= rdata;
                    pc <= pc + 1'b1;
                    state <= EXEC;

                    // Opcode decoding (decode on rdata since ir is still a cycle behind)
                    case (rdata[15:11])
                        HALT: halted <= 1'b1;
                        LDI: begin
                            // Set address to the next word after the current PC for the rdata read in the MEM state
                            addr <= pc + 1'b1;
                            state <= MEM;
                        end
                    endcase
                end
                EXEC: begin
                    state <= FETCH;
                end
                MEM: begin
                    // Read the data bus into the selected register
                    regs[ir[10:8]] <= rdata;
                    // Skip the data word by incrementing the PC again
                    pc <= pc + 1'b1;
                    state <= FETCH;
                end
                default: state <= FETCH;
            endcase

        end
    end

endmodule
