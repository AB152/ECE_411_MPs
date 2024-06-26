// function logic spec_output(logic a, logic b, logic c);
//     case ({a, b, c})
//         3'b000: return 0;
//         default: $error("Invalid input to spec_output function");
//     endcase
// endfunction





`ifndef testbench
`define testbench
module testbench(multiplier_itf.testbench itf);
import mult_types::*;

add_shift_multiplier dut (
    .clk_i          ( itf.clk          ),
    .reset_n_i      ( itf.reset_n      ),
    .multiplicand_i ( itf.multiplicand ),
    .multiplier_i   ( itf.multiplier   ),
    .start_i        ( itf.start        ),
    .ready_o        ( itf.rdy          ),
    .product_o      ( itf.product      ),
    .done_o         ( itf.done         )
);

assign itf.mult_op = dut.ms.op;
default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

// DO NOT MODIFY CODE ABOVE THIS LINE

/* Uncomment to "monitor" changes to adder operational state over time */
//initial $monitor("dut-op: time: %0t op: %s", $time, dut.ms.op.name);


// Resets the multiplier
task reset();
    itf.reset_n <= 1'b0;
    ##5;
    itf.reset_n <= 1'b1;
    ##1;
endtask : reset

// error_e defined in package mult_types in file ../include/types.sv
// Asynchronously reports error in DUT to grading harness
function void report_error(error_e error);
    itf.tb_report_dut_error(error);
endfunction : report_error


initial itf.reset_n = 1'b0;
initial begin
    reset();
    /********************** Your Code Here *****************************/
    assert(itf.rdy == 1'b1)
    else begin
            $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
            report_error (NOT_READY);
    end

    for (int i = 0; i <= 9'b100000000; ++i) begin
        for (int j = 0; j <= 9'b100000000; ++j) begin
            @(tb_clk);
            itf.multiplicand <= i;
            itf.multiplier <= j;
            itf.start <= 1'b1;
            @(tb_clk iff itf.done == 1'b1);
            assert(itf.product == itf.multiplicand * itf.multiplier)
            else begin
                $error ("%0d: %0t: BAD_PRODUCT error detected", `__LINE__, $time);
                report_error (BAD_PRODUCT);
            end
            assert(itf.rdy == 1'b1)
            else begin
                    $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
                    report_error (NOT_READY);
            end

            itf.start <= 1'b0;

            reset();
            
            assert(itf.rdy == 1'b1)
            else begin
                    $error ("%0d: %0t: NOT_READY error detected", `__LINE__, $time);
                    report_error (NOT_READY);
            end

        end
    end

    itf.start <= 1'b1;
    itf.multiplicand <= 1'b1;
    itf.multiplicand <= 1'b0;
    @(tb_clk iff itf.mult_op == SHIFT);
    itf.start <= 1'b1;

    reset();

    itf.start <= 1'b1;
    itf.multiplicand <= 1'b1;
    itf.multiplicand <= 1'b0;
    @(tb_clk iff itf.mult_op == ADD);
    itf.start <= 1'b1;

    reset();

    itf.start <= 1'b1;
    itf.multiplicand <= 1'b1;
    itf.multiplicand <= 1'b0;
    @(tb_clk iff itf.mult_op == SHIFT);
    itf.reset_n <= 1'b0;

    reset();

    itf.start <= 1'b1;
    itf.multiplicand <= 1'b1;
    itf.multiplicand <= 1'b0;
    @(tb_clk iff itf.mult_op == SHIFT);
    itf.reset_n <= 1'b0;

    /*******************************************************************/
    itf.finish(); // Use this finish task in order to let grading harness
                  // complete in process and/or scheduled operations
    $error("Improper Simulation Exit");
end


endmodule : testbench
`endif
