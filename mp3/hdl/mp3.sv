module mp3
import rv32i_types::*;
(
    input clk,
    input rst,
    input pmem_resp,
    input [63:0] pmem_rdata,
    output logic pmem_read,
    output logic pmem_write,
    output rv32i_word pmem_address,
    output [63:0] pmem_wdata
);

logic mem_resp;
rv32i_word mem_rdata;
logic mem_read;
logic mem_write;
logic [3:0] mem_byte_enable;
rv32i_word mem_address;
rv32i_word mem_wdata;

logic [255:0] pmem_rdata_256;
logic [255:0] pmem_wdata_256;
rv32i_word pmem_address_cache;
logic pmem_read_cache;
logic pmem_write_cache;
logic pmem_resp_cache;



// Keep cpu named `cpu` for RVFI Monitor
// Note: you have to rename your mp2 module to `cpu`
cpu cpu(
    .clk(clk),
    .rst(rst),
    .mem_resp(mem_resp),
    .mem_rdata(mem_rdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_address(mem_address),
    .mem_wdata(mem_wdata)
);

// Keep cache named `cache` for RVFI Monitor
cache cache(
    .clk(clk),
    .rst(rst),
    /* CPU memory signals */
    .mem_address(mem_address),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_read(mem_read),
    .mem_write(mem_write),
    .mem_byte_enable(mem_byte_enable),
    .mem_resp(mem_resp),

    /* Physical memory signals */
    .pmem_address(pmem_address_cache),
    .pmem_rdata(pmem_rdata_256),
    .pmem_wdata(pmem_wdata_256),
    .pmem_read(pmem_read_cache),
    .pmem_write(pmem_write_cache),
    .pmem_resp(pmem_resp_cache)

    // .pmem_rdata_256(pmem_rdata_256),
    // .pmem_wdata_256(pmem_wdata_256),
    // .pmem_address_cache(pmem_address_cache),
    // .pmem_read_cache(pmem_read_cache),
    // .pmem_write_cache(pmem_write_cache),
    // .pmem_resp_cache(pmem_resp_cache)
);

// Hint: What do you need to interface between cache and main memory? cacheline_adaptor
cacheline_adaptor cacheline_adaptor(
    .clk(clk),
    .reset_n(~rst),
    
    // Port to LLC (Lowest Level Cache)
    .line_i(pmem_wdata_256),
    .line_o(pmem_rdata_256),
    .address_i(pmem_address_cache),
    .read_i(pmem_read_cache),
    .write_i(pmem_write_cache),
    .resp_o(pmem_resp_cache),

    // Port to memory
    .burst_i(pmem_rdata),
    .burst_o(pmem_wdata),
    .address_o(pmem_address),
    .read_o(pmem_read),
    .write_o(pmem_write),
    .resp_i(pmem_resp)
);

endmodule : mp3