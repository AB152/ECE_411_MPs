`ifndef testbench
`define testbench


module testbench(fifo_itf itf);
import fifo_types::*;

fifo_synch_1r1w dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),

    // valid-ready enqueue protocol
    .data_i    ( itf.data_i  ),
    .valid_i   ( itf.valid_i ),
    .ready_o   ( itf.rdy     ),

    // valid-yumi deqeueue protocol
    .valid_o   ( itf.valid_o ),
    .data_o    ( itf.data_o  ),
    .yumi_i    ( itf.yumi    )
);

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

// Clock Synchronizer for Student Use
default clocking tb_clk @(negedge itf.clk); endclocking

task reset();
    itf.reset_n <= 1'b0;
    ##(10);
    itf.reset_n <= 1'b1;
    ##(1);
endtask : reset

function automatic void report_error(error_e err); 
    itf.tb_report_dut_error(err);
endfunction : report_error

// DO NOT MODIFY CODE ABOVE THIS LINE

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    assert(itf.rdy == 1'b1)
    else begin
            $error ("%0d: %0t: RESET_DOES_NOT_CAUSE_READY_O error detected", `__LINE__, $time);
            report_error (RESET_DOES_NOT_CAUSE_READY_O);
    end
    for (int i = 0; i < 9'b100000000; ++i) begin
        @(tb_clk);
        itf.data_i <= i;
        @(tb_clk);
        itf.valid_i <= 1;
        @(tb_clk);
        itf.valid_i <= 0;
        // There are only 2 types of errors, so no need to assert (check) here
    end

    for (int i = 0; i < 9'b100000000; ++i) begin
        @(tb_clk);
        itf.yumi <= 1;
        // Since it is a fifo, verify i
        assert(itf.data_o == i)
        else begin
            $error ("%0d: %0t: INCORRECT_DATA_O_ON_YUMI_I error detected", `__LINE__, $time);
            report_error (INCORRECT_DATA_O_ON_YUMI_I);
        end
        @(tb_clk);
        itf.yumi <= 0;
    end


    for (int i = 0; i <= 9'b100000000; ++i) begin
        @(tb_clk);
        itf.data_i <= i;
        @(tb_clk);
        itf.valid_i <= 1;

        @(tb_clk)
        itf.yumi <= 1;

        @(tb_clk);
        itf.yumi <= 0;
        // @(tb_clk);
        itf.valid_i <= 0;

    end

    /***************************************************************/
    // Make sure your test bench exits by calling itf.finish();
    itf.finish();
    $error("TB: Illegal Exit ocurred");
end

endmodule : testbench
`endif

