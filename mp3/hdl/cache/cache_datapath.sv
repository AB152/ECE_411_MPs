/* MODIFY. The cache datapath. It contains the data,
valid, dirty, tag, and LRU arrays, comparators, muxes,
logic gates and other supporting logic. */

module cache_datapath
// import rv32i_types::*;
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

    input logic [31:0] mem_address,
    input logic [255:0] mem_wdata256,
    output logic [255:0] mem_rdata256,
    input logic [31:0] mem_byte_enable256,
    input logic mem_read,
    input logic mem_write,

    // State machine variables
    output logic miss_overall,
    output logic dirty_overall,
    output logic hit_overall,
    // input pmem_write,
    // input pmem_read,
    // input logic write_cache,
    input logic data_in_sel,
    input logic write_back_state,
    input logic load_tag,
    input logic load_valid,
    input logic load_dirty,
    input logic load_data,
    input logic in_compare_tag,

    input logic [255:0] pmem_rdata_256,
    output logic [255:0] pmem_wdata_256,
    output logic [31:0] pmem_address_cache
    // output logic pmem_read_cache,
    // output logic pmem_write_cache,
    // input logic pmem_resp_cache


);





logic [255:0] data_array_in;
logic [255:0] data_0;
logic [255:0] data_1;
logic [23:0] tag_0;
logic [23:0] tag_1;
logic valid_0;
logic valid_1;
logic dirty_0;
logic dirty_1;
logic lru_o;



logic load_tag_0;
logic load_tag_1;
logic load_valid_0;
logic load_valid_1;
logic load_dirty_0;
logic load_dirty_1;
logic load_data_0;
logic load_data_1;

logic [31:0] write_en_0;
logic [31:0] write_en_1;
logic hit_0;
logic hit_1;
logic [31:0] temp_mem_address;


data_array Data_0 (
    .clk(clk),
    .read(1'b1),
    .write_en(write_en_0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(data_array_in),
    .dataout(data_0)
);

data_array Data_1 (
    .clk(clk),
    .read(1'b1),
    .write_en(write_en_1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(data_array_in),
    .dataout(data_1)
);

array #(3, 24) Tag_0 (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag_0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_0)
);

array #(3, 24) Tag_1 (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_tag_1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(mem_address[31:8]),
    .dataout(tag_1)
);

array #(3, 1) Valid_0 (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(1'b1),
    .dataout(valid_0)
);

array #(3, 1) Valid_1 (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_valid_1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(1'b1),
    .dataout(valid_1)
);

array #(3, 1) Dirty_0 (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty_0),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(1'b1),
    .dataout(dirty_0)
);

array #(3, 1) Dirty_1 (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(load_dirty_1),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(1'b1),
    .dataout(dirty_1)
);

array #(3, 1) LRU_0 (
    .clk(clk),
    .rst(rst),
    .read(1'b1),
    .load(hit_overall),
    .rindex(mem_address[7:5]),
    .windex(mem_address[7:5]),
    .datain(hit_0),
    .dataout(lru_o)
);

always_comb begin

    // hit_0 = (mem_address[31:8] == tag_0 ? 1'b1 : 1'b0) & valid_0;
    // hit_1 = (mem_address[31:8] == tag_1 ? 1'b1 : 1'b0) & valid_1;
    // load_0 = ((mem_write ^ mem_read) & hit_0) | (~lru_o & write_cache);
    // load_1 = ((mem_write ^ mem_read) & hit_1) | (lru_o & write_cache);

    // write_en_0 = mem_byte_enable256 | {32{load_0}};

    // // 0x0000000f & 0xffffffff = 0x0000000f;
    // // 0x0000000f | 0xffffffff = 0xffffffff;
    // // 0x0000000f | 0x00000000 = 0x0000000f;

    // /*
    // 32'b0;
    // 32'b1;
    // mem_byte_enable256
    // */
    // write_en_1 = mem_byte_enable256 | {32{load_1}};

    load_tag_0 = (load_tag & hit_0 & in_compare_tag & ~lru_o) | (data_in_sel & ~lru_o);
    load_tag_1 = (load_tag & hit_1 & in_compare_tag & lru_o) | (data_in_sel & lru_o);

    load_valid_0 = (load_valid & hit_0 & in_compare_tag & ~lru_o) | (data_in_sel & ~lru_o);
    load_valid_1 = (load_valid & hit_1 & in_compare_tag & lru_o) | (data_in_sel & lru_o);

    load_dirty_0 = load_dirty & in_compare_tag & ~lru_o;
    load_dirty_1 = load_dirty & in_compare_tag & lru_o;

    load_data_0 = (load_data & ~lru_o);// | (in_compare_tag & hit_0);
    load_data_1 = (load_data & lru_o);// | (in_compare_tag & hit_1);

// should be 0 on hit_overall
    if(hit_overall & mem_read) begin
        write_en_0 = 32'b0;
    end
    else if(mem_read) begin
        write_en_0 = {32{load_data_0}};
    end
    else if(mem_write) begin
        write_en_0 = mem_byte_enable256;
    end
    else begin
        write_en_0 = 32'b0;
    end

    if(hit_overall & mem_read) begin
        write_en_1 = 32'b0;
    end
    else if(mem_read) begin
        write_en_1 = {32{load_data_1}};
    end
    else if(mem_write) begin
        write_en_1 = mem_byte_enable256;
    end
    else begin
        write_en_1 = 32'b0;
    end
    // write_en_0 = (hit_overall & mem_read) ? 32'b0 : mem_byte_enable256 | {32{load_data_0}};
    // write_en_1 = (hit_overall & mem_read) ? 32'b0 : mem_byte_enable256 | {32{load_data_1}};

    // 0x0000000f & 0xffffffff = 0x0000000f;
    // 0x0000000f | 0xffffffff = 0xffffffff;
    // 0x0000000f | 0x00000000 = 0x0000000f;

    /*
    32'b0;
    32'b1;
    mem_byte_enable256
    */

    hit_0 = (mem_address[31:8] == tag_0 ? 1'b1 : 1'b0) & valid_0 & in_compare_tag;
    hit_1 = (mem_address[31:8] == tag_1 ? 1'b1 : 1'b0) & valid_1 & in_compare_tag;

    hit_overall = (mem_write ^ mem_read) & (hit_0 ^ hit_1) & in_compare_tag;
    miss_overall = (mem_write ^ mem_read) & (~hit_overall) & in_compare_tag;





    // MUXES

    unique case(data_in_sel)
        1'b0: data_array_in = mem_wdata256;
        1'b1: data_array_in = pmem_rdata_256;
        default: data_array_in = mem_wdata256;
    endcase

    unique case(hit_0)
        1'b0: mem_rdata256 = data_1;
        1'b1: mem_rdata256 = data_0;
        default: mem_rdata256 = 256'b0;
    endcase

    unique case(lru_o)
        1'b0: pmem_wdata_256 = data_0;
        1'b1: pmem_wdata_256 = data_1;
        default: pmem_wdata_256 = data_0;
    endcase

    unique case(lru_o)
        1'b0: dirty_overall = dirty_0;
        1'b1: dirty_overall = dirty_1;
        default: dirty_overall = dirty_0;
    endcase

    unique case(lru_o)
        1'b0: temp_mem_address = {tag_0, mem_address[7:5], 5'b00000};
        1'b1: temp_mem_address = {tag_1, mem_address[7:5], 5'b00000};
        default: temp_mem_address = {tag_0, mem_address[7:5], 5'b00000};
    endcase

    unique case(write_back_state)
        1'b0: pmem_address_cache = {mem_address[31:5], 5'b00000};
        1'b1: pmem_address_cache = temp_mem_address;
        default: pmem_address_cache = {mem_address[31:5], 5'b00000};
    endcase
end

endmodule : cache_datapath
































































// /* MODIFY. The cache datapath. It contains the data,
// valid, dirty, tag, and LRU arrays, comparators, muxes,
// logic gates and other supporting logic. */

// module cache_datapath
// // import rv32i_types::*;
// #(
//     parameter s_offset = 5,
//     parameter s_index  = 3,
//     parameter s_tag    = 32 - s_offset - s_index,
//     parameter s_mask   = 2**s_offset,
//     parameter s_line   = 8*s_mask,
//     parameter num_sets = 2**s_index
// )
// (
//     input clk,
//     input rst,

//     input logic [31:0] mem_address,
//     input logic [255:0] mem_wdata256,
//     output logic [255:0] mem_rdata256,
//     input logic [31:0] mem_byte_enable256,
//     input logic mem_read,
//     input logic mem_write,

//     // State machine variables
//     output logic miss_overall,
//     output logic dirty_overall,
//     output logic hit_overall,
//     // input pmem_write,
//     // input pmem_read,
//     // input logic write_cache,
//     input logic data_in_sel,
//     input logic write_back_state,
//     input logic load_tag,
//     input logic load_valid,
//     input logic load_dirty,
//     input logic load_data,
//     input logic in_compare_tag,

//     input logic [255:0] pmem_rdata_256,
//     output logic [255:0] pmem_wdata_256,
//     output logic [31:0] pmem_address_cache
//     // output logic pmem_read_cache,
//     // output logic pmem_write_cache,
//     // input logic pmem_resp_cache


// );





// logic [255:0] data_array_in;
// logic [255:0] data_0;
// logic [255:0] data_1;
// logic [23:0] tag_0;
// logic [23:0] tag_1;
// logic valid_0;
// logic valid_1;
// logic dirty_0;
// logic dirty_1;
// logic lru_o;



// logic load_tag_0;
// logic load_tag_1;
// logic load_valid_0;
// logic load_valid_1;
// logic load_dirty_0;
// logic load_dirty_1;
// logic load_data_0;
// logic load_data_1;

// logic [31:0] write_en_0;
// logic [31:0] write_en_1;
// logic hit_0;
// logic hit_1;
// logic [31:0] temp_mem_address;


// data_array Data_0 (
//     .clk(clk),
//     .read(1'b1),
//     .write_en(write_en_0),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(data_array_in),
//     .dataout(data_0)
// );

// data_array Data_1 (
//     .clk(clk),
//     .read(1'b1),
//     .write_en(write_en_1),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(data_array_in),
//     .dataout(data_1)
// );

// array #(3, 24) Tag_0 (
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_tag_0),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(mem_address[31:8]),
//     .dataout(tag_0)
// );

// array #(3, 24) Tag_1 (
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_tag_1),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(mem_address[31:8]),
//     .dataout(tag_1)
// );

// array #(3, 1) Valid_0 (
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_valid_0),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(1'b1),
//     .dataout(valid_0)
// );

// array #(3, 1) Valid_1 (
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_valid_1),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(1'b1),
//     .dataout(valid_1)
// );

// array #(3, 1) Dirty_0 (
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_dirty_0),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(1'b1),
//     .dataout(dirty_0)
// );

// array #(3, 1) Dirty_1 (
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(load_dirty_1),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(1'b1),
//     .dataout(dirty_1)
// );

// array #(3, 1) LRU_0 (
//     .clk(clk),
//     .rst(rst),
//     .read(1'b1),
//     .load(hit_overall & in_compare_tag),
//     .rindex(mem_address[7:5]),
//     .windex(mem_address[7:5]),
//     .datain(hit_0),
//     .dataout(lru_o)
// );

// always_comb begin

//     // hit_0 = (mem_address[31:8] == tag_0 ? 1'b1 : 1'b0) & valid_0;
//     // hit_1 = (mem_address[31:8] == tag_1 ? 1'b1 : 1'b0) & valid_1;
//     // load_0 = ((mem_write ^ mem_read) & hit_0) | (~lru_o & write_cache);
//     // load_1 = ((mem_write ^ mem_read) & hit_1) | (lru_o & write_cache);

//     // write_en_0 = mem_byte_enable256 | {32{load_0}};

//     // // 0x0000000f & 0xffffffff = 0x0000000f;
//     // // 0x0000000f | 0xffffffff = 0xffffffff;
//     // // 0x0000000f | 0x00000000 = 0x0000000f;

//     // /*
//     // 32'b0;
//     // 32'b1;
//     // mem_byte_enable256
//     // */
//     // write_en_1 = mem_byte_enable256 | {32{load_1}};

//     load_tag_0 = (load_tag & hit_0 & in_compare_tag & ~lru_o) | (data_in_sel & ~lru_o);
//     load_tag_1 = (load_tag & hit_1 & in_compare_tag & lru_o) | (data_in_sel & lru_o);

//     load_valid_0 = (load_valid & hit_0 & in_compare_tag & ~lru_o) | (data_in_sel & ~lru_o);
//     load_valid_1 = (load_valid & hit_1 & in_compare_tag & lru_o) | (data_in_sel & lru_o);

//     load_dirty_0 = load_dirty & in_compare_tag & ~lru_o;
//     load_dirty_1 = load_dirty & in_compare_tag & lru_o;

//     load_data_0 = (load_data & ~lru_o);// | (in_compare_tag & hit_0);
//     load_data_1 = (load_data & lru_o);// | (in_compare_tag & hit_1);

// // should be 0 on hit_overall
//     if(hit_0 & mem_read) begin
//         write_en_0 = 32'b0;
//     end
//     else if(mem_read) begin
//         write_en_0 = {32{load_data_0}};
//     end
//     else if(mem_write) begin
//         write_en_0 = mem_byte_enable256 | {32{load_data_0}};
//     end
//     else begin
//         write_en_0 = 32'b0;
//     end

//     if(hit_1 & mem_read) begin
//         write_en_1 = 32'b0;
//     end
//     else if(mem_read) begin
//         write_en_1 = {32{load_data_1}};
//     end
//     else if(mem_write) begin
//         write_en_1 = mem_byte_enable256 | {32{load_data_1}};
//     end
//     else begin
//         write_en_1 = 32'b0;
//     end
//     // write_en_0 = (hit_overall & mem_read) ? 32'b0 : mem_byte_enable256 | {32{load_data_0}};
//     // write_en_1 = (hit_overall & mem_read) ? 32'b0 : mem_byte_enable256 | {32{load_data_1}};

//     // 0x0000000f & 0xffffffff = 0x0000000f;
//     // 0x0000000f | 0xffffffff = 0xffffffff;
//     // 0x0000000f | 0x00000000 = 0x0000000f;

//     /*
//     32'b0;
//     32'b1;
//     mem_byte_enable256
//     */

//     hit_0 = (mem_address[31:8] == tag_0 ? 1'b1 : 1'b0) & valid_0 & in_compare_tag;
//     hit_1 = (mem_address[31:8] == tag_1 ? 1'b1 : 1'b0) & valid_1 & in_compare_tag;

//     hit_overall = (mem_write ^ mem_read) & (hit_0 ^ hit_1) & in_compare_tag;
//     miss_overall = (mem_write ^ mem_read) & (~hit_overall) & in_compare_tag;





//     // MUXES

//     unique case(data_in_sel)
//         1'b0: data_array_in = mem_wdata256;
//         1'b1: data_array_in = pmem_rdata_256;
//         default: data_array_in = mem_wdata256;
//     endcase

//     unique case(hit_0)
//         1'b0: mem_rdata256 = data_1;
//         1'b1: mem_rdata256 = data_0;
//         default: mem_rdata256 = 256'b0;
//     endcase

//     unique case(lru_o)
//         1'b0: pmem_wdata_256 = data_0;
//         1'b1: pmem_wdata_256 = data_1;
//         default: pmem_wdata_256 = data_0;
//     endcase

//     unique case(lru_o)
//         1'b0: dirty_overall = dirty_0;
//         1'b1: dirty_overall = dirty_1;
//         default: dirty_overall = dirty_0;
//     endcase

//     unique case(lru_o)
//         1'b0: temp_mem_address = {tag_0, mem_address[7:5], 5'b00000};
//         1'b1: temp_mem_address = {tag_1, mem_address[7:5], 5'b00000};
//         default: temp_mem_address = {tag_0, mem_address[7:5], 5'b00000};
//     endcase

//     unique case(write_back_state)
//         1'b0: pmem_address_cache = {mem_address[31:5], 5'b00000};
//         // 1'b0: pmem_address_cache = mem_address;
//         1'b1: pmem_address_cache = temp_mem_address;
//         default: pmem_address_cache = {mem_address[31:5], 5'b00000};
//     endcase
// end

// endmodule : cache_datapath
