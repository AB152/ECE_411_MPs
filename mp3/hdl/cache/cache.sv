/* MODIFY. Your cache design. It contains the cache
controller, cache datapath, and bus adapter. */

module cache 
import rv32i_types::*;
#(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index
)
(
    input clk,
    input rst,

    /* CPU memory signals */
    input   logic [31:0]    mem_address,
    output  logic [31:0]    mem_rdata,
    input   logic [31:0]    mem_wdata,
    input   logic           mem_read,
    input   logic           mem_write,
    input   logic [3:0]     mem_byte_enable,
    output  logic           mem_resp,

    /* Physical memory signals */
    output  logic [31:0]    pmem_address,
    input   logic [255:0]   pmem_rdata,
    output  logic [255:0]   pmem_wdata,
    output  logic           pmem_read,
    output  logic           pmem_write,
    input   logic           pmem_resp

    // output logic [255:0] pmem_rdata_256,
    // input logic [255:0] pmem_wdata_256,
    // output rv32i_word pmem_address_cache,
    // output logic pmem_read_cache,
    // output logic pmem_write_cache,
    // input logic pmem_resp_cache
);

logic miss_overall;
logic dirty_overall;
// logic hit_overall;
// logic pmem_write_cache;
// logic pmem_read_cache;
// logic write_cache;
logic data_in_sel;
logic write_back_state;
logic load_tag;
logic load_valid;
logic load_dirty;
logic load_data;
logic in_compare_tag;

logic [255:0] mem_wdata256;
logic [255:0] mem_rdata256;
logic [31:0] mem_byte_enable256;


// assign mem_resp = hit_overall;

cache_control control
(
    .clk(clk),
    .rst(rst),
    .miss_overall(miss_overall),
    .dirty_overall(dirty_overall),
    .hit_overall(mem_resp),
    .pmem_resp(pmem_resp),
    .pmem_write(pmem_write),
    .pmem_read(pmem_read),
    .mem_read(mem_read),
    .mem_write(mem_write),
    // .write_cache(write_cache),
    .data_in_sel(data_in_sel),
    .write_back_state(write_back_state),
    .load_tag(load_tag),
    .load_valid(load_valid),
    .load_dirty(load_dirty),
    .load_data(load_data),
    .in_compare_tag(in_compare_tag)
);

cache_datapath datapath
(
    .*,
    .miss_overall(miss_overall),
    .dirty_overall(dirty_overall),
    .hit_overall(mem_resp),
    // .pmem_write(pmem_write_cache),
    // .pmem_read(pmem_read_cache),
    // .write_cache(write_cache),
    .data_in_sel(data_in_sel),
    .write_back_state(write_back_state),
    .load_tag(load_tag),
    .load_valid(load_valid),
    .load_dirty(load_dirty),
    .load_data(load_data),
    .in_compare_tag(in_compare_tag),

    .mem_address(mem_address),
    .mem_wdata256(mem_wdata256), // Interface with memory
    .mem_rdata256(mem_rdata256), // Interface with memory
    .mem_byte_enable256(mem_byte_enable256), // Interface with memory
    .mem_read(mem_read),
    .mem_write(mem_write),

    .pmem_rdata_256(pmem_rdata),
    .pmem_wdata_256(pmem_wdata),
    .pmem_address_cache(pmem_address)
    // .pmem_read_cache(pmem_read_cache),
    // .pmem_write_cache(pmem_write_cache),
    // .pmem_resp_cache(pmem_resp_cache)

);

bus_adapter bus_adapter
(
    .mem_wdata256(mem_wdata256), // Interface with memory
    .mem_rdata256(mem_rdata256), // Interface with memory
    .mem_wdata(mem_wdata), // Interface with CPU
    .mem_rdata(mem_rdata), // Interface with CPU
    .mem_byte_enable(mem_byte_enable), // Interface with CPU
    .mem_byte_enable256(mem_byte_enable256), // Interface with memory
    .address(mem_address) // Interface with CPU
);

endmodule : cache
