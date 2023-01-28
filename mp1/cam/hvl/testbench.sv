
module testbench(cam_itf itf);
import cam_types::*;

cam dut (
    .clk_i     ( itf.clk     ),
    .reset_n_i ( itf.reset_n ),
    .rw_n_i    ( itf.rw_n    ),
    .valid_i   ( itf.valid_i ),
    .key_i     ( itf.key     ),
    .val_i     ( itf.val_i   ),
    .val_o     ( itf.val_o   ),
    .valid_o   ( itf.valid_o )
);

default clocking tb_clk @(negedge itf.clk); endclocking

initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars();
end

task reset();
    itf.reset_n <= 1'b0;
    repeat (5) @(tb_clk);
    itf.reset_n <= 1'b1;
    repeat (5) @(tb_clk);
endtask

// DO NOT MODIFY CODE ABOVE THIS LINE

// Needed because of itf.valid_i <= 0 in write task below
task writeConsecutive(input key_t key, input val_t val);
    itf.valid_i <= 1;
    itf.key <= key;
    itf.val_i <= val;
    itf.rw_n <= 0;
    
endtask

task write(input key_t key, input val_t val);
    itf.valid_i <= 1;
    itf.key <= key;
    itf.val_i <= val;
    itf.rw_n <= 0;
    @(tb_clk);
    itf.valid_i <= 0;
    
endtask


task read(input key_t key, output val_t val);
    itf.valid_i <= 1;
    itf.key <= key;
    itf.rw_n <= 1;
    @(tb_clk);
    val <= itf.val_o;
    itf.valid_i <= 0;
    @(tb_clk);

endtask

val_t res = 0;

initial begin
    $display("Starting CAM Tests");

    reset();
    /************************** Your Code Here ****************************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // Consider using the task skeltons above
    // To report errors, call itf.tb_report_dut_error in cam/include/cam_itf.sv
    for (int i = 16'h0000; i < 16'h0008; ++i) begin
        write(i, i + 1);
    end

    // Tests evict
    for (int i = 16'h0000; i < 16'h0008; ++i) begin
        write(i + 10, i + 11);
    end

    for (int i = 16'h0000; i < 16'h0008; ++i) begin
        write(i, i + 1);
    end

    // Tests read at all 8 indices
    for (int i = 16'h0000; i < 16'h0008; ++i) begin
        read(i, res);
        @(tb_clk)
        assert (itf.val_o == res) else  begin
            itf.tb_report_dut_error(READ_ERROR);
            $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, i+1);
        end
    end

    // Write to same key in consecutive clock cycles
    @(tb_clk);
    writeConsecutive(16'h0001, 16'h0001);
    @(tb_clk);
    writeConsecutive(16'h0001, 16'h0002);
    @(tb_clk);


    // Write to and read same key in consecutive clock cycles
    @(tb_clk);
    writeConsecutive(16'h0001, 16'h0001);
    @(tb_clk);
    read(16'h0001, res);
    @(tb_clk);
    assert (itf.val_o == res) else  begin
        itf.tb_report_dut_error(READ_ERROR);
        $error("%0t TB: Read %0d, expected %0d", $time, itf.val_o, 16'h0001);
    end

    /**********************************************************************/

    itf.finish();
end

endmodule : testbench
