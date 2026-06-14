`timescale 1ns/1ps

module smelt_alu (
    input [15:0] a,
    input [15:0] b,
    input [4:0] op,
    output [15:0] result,
    output zero,
    output carry
);

`include "opcodes.vh"

reg [16:0] buffer;      // combinational; defaulted in the always block below

assign result = buffer[15:0];
assign zero = (result == 16'b0);
assign carry = buffer[16];

always @(*) begin
    buffer = 17'b0;
    case(op)
        ADD: begin
            buffer = a + b;
        end
        SUB, CMP: begin
            buffer = {(a >= b), a - b};
        end
        AND: begin
            buffer = a & b;
        end
        OR: begin
            buffer = a | b;
        end
        XOR: begin
            buffer = a ^ b;
        end
        SHL: begin
            buffer = a << 1;
        end
        SHR: begin
            buffer = {a[0], a >> 1};
        end
    endcase
end

endmodule
