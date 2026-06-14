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
    wire        error;

    // Smelt CPU DUT
    smelt_cpu cpu (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .wdata(wdata),
        .we(we),
        .rdata(rdata),
        .halted(halted),
        .error(error)
    );

    // Simulated memory
    memory mem (
        .clk(clk),
        .addr(addr),
        .wdata(wdata),
        .we(we),
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
    wire [2:0] rd = (cpu.state == cpu.EXEC || cpu.state == cpu.MEM) ? cpu.ir[10:8] : 3'bx;
    wire [2:0] rs = (cpu.state == cpu.EXEC || cpu.state == cpu.MEM) ? cpu.ir[7:5] : 3'bx;

    // Self-checking harness
    // Each program submits results by storing to the output port (0xFFFF).
    // We compare that submit-stream, in order, against a golden file loaded
    // at run time. Both files are selectable per run:
    //   vvp sim/smelt.vvp +hex=asm/nop_test.hex +golden=asm/nop_test.golden

    // Golden format: one row per submission, three hex tokens -> RESULT Z C.
    // Use xxxx in any column for "don't care" (skips that comparison) -- needed
    // for CMP (no register result) or ops that leave a flag untouched.
    localparam   MAXCASES = 256;
    reg [15:0]   golden [0:3*MAXCASES-1];   // 3 words per case (x-initialized)
    reg [1023:0] goldenfile;
    integer      case_idx = 0;     // which submission we're on
    integer      errors   = 0;
    integer      n_golden = 0;     // number of real golden rows (early-halt guard)
    integer      gi;
    reg          done;
    reg          expect_error;     // +expect_error=1 for the illegal-opcode suite

    initial begin
        if (!$value$plusargs("golden=%s", goldenfile))
            goldenfile = "asm/nop_test.golden";   // default when no +golden= is given
        // Does this program expect to fault? Default: no (must finish error-free).
        if (!$value$plusargs("expect_error=%d", expect_error))
            expect_error = 1'b0;
        $readmemh(goldenfile, golden);
        // Count rows until the first all-x (unused) row -> that's the table length.
        done = 1'b0;
        for (gi = 0; gi < 3*MAXCASES && !done; gi = gi + 3) begin
            if (golden[gi]   === 16'hxxxx &&
                golden[gi+1] === 16'hxxxx &&
                golden[gi+2] === 16'hxxxx)
                done = 1'b1;
            else
                n_golden = n_golden + 1;
        end
    end

    // Compare one submission (result + Z + C) against its golden row.
    // exp_* are the 16-bit golden words; xxxx means "don't care" for that column.
    task check(input integer idx,
               input [15:0] got_r, input got_z, input got_c,
               input [15:0] exp_r, input [15:0] exp_z, input [15:0] exp_c);
        reg ok;
        begin
            ok = 1'b1;
            if (exp_r !== 16'hxxxx && got_r !== exp_r) begin
                $display("  FAIL case[%0d] result: got=%h exp=%h", idx, got_r, exp_r);
                ok = 1'b0;
            end
            if (exp_z !== 16'hxxxx && got_z !== exp_z[0]) begin
                $display("  FAIL case[%0d] Z: got=%0d exp=%0d", idx, got_z, exp_z[0]);
                ok = 1'b0;
            end
            if (exp_c !== 16'hxxxx && got_c !== exp_c[0]) begin
                $display("  FAIL case[%0d] C: got=%0d exp=%0d", idx, got_c, exp_c[0]);
                ok = 1'b0;
            end
            if (!ok) errors = errors + 1;
            else $display("  PASS case[%0d]: r=%h z=%0d c=%0d", idx, got_r, got_z, got_c);
        end
    endtask

    // Every store to the output port is one submission. We sample the result on
    // the bus plus the live flags -- the op under test set them, and nothing
    // between it and this ST touches flags in this non-pipelined core.
    always @(posedge clk) begin
        if (!rst && we && addr == 16'hFFFF) begin
            check(case_idx,
                  wdata, cpu.flag_zero, cpu.flag_carry,
                  golden[3*case_idx + 0],
                  golden[3*case_idx + 1],
                  golden[3*case_idx + 2]);
            case_idx = case_idx + 1;
        end
    end

    // Termination + verdict: fires on a clean HALT or a fault stop.
    always @(posedge clk) begin
        if (error || halted) begin
            if (error) $display("ERROR");
            else       $display("HALT");

            // Fault status must match what this program expects
            // (+expect_error=1 for the illegal-opcode suite; default 0).
            if (error !== expect_error) begin
                $display("  FAIL error: expected %0d, got %0d", expect_error, error);
                errors = errors + 1;
            end

            // Did we get exactly as many submissions as the golden file expects?
            if (case_idx !== n_golden) begin
                $display("  FAIL count: expected %0d submits, got %0d", n_golden, case_idx);
                errors = errors + 1;
            end

            if (errors == 0) $display("ALL_PASS");
            else             $display("FAILURES=%0d", errors);
            $finish;
        end
    end

    // Safety timeout
    initial begin
        #100000;
        $display("Timed out!");
        $finish;
    end

endmodule
