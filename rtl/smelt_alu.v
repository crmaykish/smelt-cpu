`timescale 1ns/1ps

module smelt_alu (
    input [15:0] a,
    input [15:0] b,
    input [4:0] op,
    output reg [15:0] result,
    output reg zero,
    output carry
);

`include "opcodes.vh"

reg [16:0] buffer = 17'b0;

assign carry = buffer[16];

always @(*) begin
    if (op == ADD) begin
        buffer = a + b;
        result = buffer[15:0];
        zero = (result == 16'b0);
    end
end

endmodule
