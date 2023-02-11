// import pcmux::*;
// import marmux::*;
// import cmpmux::*;
// import alumux::*;
// import regfilemux::*;
import rv32i_types::*; /* Import types defined in rv32i_types.sv */
module datapath
import rv32i_types::*;
(
    input clk,
    input rst,
    input load_mdr,
    input rv32i_word mem_rdata,
    output rv32i_word mem_wdata, // signal used by RVFI Monitor
    /* You will need to connect more signals to your datapath module*/
    output rv32i_opcode opcode,
    output logic [2:0] funct3,
    output logic [6:0] funct7,
    output logic br_en,
    output logic [4:0] rs1,
    output logic [4:0] rs2,
    output rv32i_word mem_address,
    output rv32i_word alu_out,

    input pcmux::pcmux_sel_t pcmux_sel,
    input alumux::alumux1_sel_t alumux1_sel,
    input alumux::alumux2_sel_t alumux2_sel,
    input regfilemux::regfilemux_sel_t regfilemux_sel,
    input marmux::marmux_sel_t marmux_sel,
    input cmpmux::cmpmux_sel_t cmpmux_sel,
    input rv32i_types::alu_ops aluop,
    input logic load_pc,
    input logic load_ir,
    input logic load_regfile,
    input logic load_mar,
    input logic load_data_out,
    // Extra Signals
    input rv32i_types::branch_funct3_t cmpop
);

/******************* Signals Needed for RVFI Monitor *************************/
rv32i_word pcmux_out;
rv32i_word mdrreg_out;
logic [4:0] rd;
rv32i_word rs1_out;
rv32i_word rs2_out;
rv32i_word i_imm;
rv32i_word u_imm;
rv32i_word b_imm;
rv32i_word s_imm;
rv32i_word j_imm;
rv32i_word alumux1_out;
rv32i_word alumux2_out;
rv32i_word regfilemux_out;
rv32i_word marmux_out;
rv32i_word cmp_mux_out;
// rv32i_word alu_out;
// assign alu_out_ = alu_out;
rv32i_word pc_out;
rv32i_word pc_plus4_out;
rv32i_word temp_mem_address;
rv32i_word mem_data_out;

assign mem_address = temp_mem_address & 32'hFFFFFFFC;
/*****************************************************************************/


/***************************** Registers *************************************/
// Keep Instruction register named `IR` for RVFI Monitor
ir IR(
    .clk(clk),
    .rst(rst),
    .load(load_ir),
    .in(mdrreg_out),
    .funct3(funct3),
    .funct7(funct7),
    .opcode(opcode),
    .i_imm(i_imm),
    .s_imm(s_imm),
    .b_imm(b_imm),
    .u_imm(u_imm),
    .j_imm(j_imm),
    .rs1(rs1),
    .rs2(rs2),
    .rd(rd)
);

register MDR(
    .clk  (clk),
    .rst (rst),
    .load (load_mdr),
    .in   (mem_rdata),
    .out  (mdrreg_out)
);

regfile regfile(
    .clk (clk),
    .rst (rst),
    .load (load_regfile),
    .in (regfilemux_out),
    .src_a (rs1),
    .src_b (rs2),
    .dest(rd),
    .reg_a(rs1_out),
    .reg_b(rs2_out)
);

pc_register PC(
    .clk(clk),
    .rst(rst),
    .load(load_pc),
    .in(pcmux_out),
    .out(pc_out)
);

register MAR(
    .clk  (clk),
    .rst (rst),
    .load (load_mar),
    .in   (marmux_out),
    .out  (temp_mem_address)
);

register MEM_DATA_OUT(
    .clk  (clk),
    .rst (rst),
    .load (load_data_out),
    .in   (mem_data_out),
    .out  (mem_wdata)
);

/*****************************************************************************/

/******************************* ALU and CMP *********************************/
alu ALU(
    .aluop (aluop),
    .a (alumux1_out),
    .b (alumux2_out),
    .f (alu_out)
);

cmp CMP(
    .cmpop (cmpop),
    .rs1_out (rs1_out),
    .cmp_mux_out (cmp_mux_out),
    .br_en (br_en)
);
/*****************************************************************************/

/******************************** Muxes **************************************/
always_comb begin : MUXES
    // We provide one (incomplete) example of a mux instantiated using
    // a case statement.  Using enumerated types rather than bit vectors
    // provides compile time type safety.  Defensive programming is extremely
    // useful in SystemVerilog. 


    unique case (pcmux_sel)
        pcmux::pc_plus4: pcmux_out = pc_out + 4;
        pcmux::alu_out: pcmux_out = alu_out;
        pcmux::alu_mod2: pcmux_out = alu_out & 32'hFFFFFFFC;
        // etc.
    endcase

    unique case (alumux1_sel)
        alumux::rs1_out: alumux1_out = rs1_out;
        alumux::pc_out: alumux1_out = pc_out;
        // etc.
    endcase

    unique case (alumux2_sel)
        alumux::i_imm: alumux2_out = i_imm;
        alumux::u_imm: alumux2_out = u_imm;
        alumux::b_imm: alumux2_out = b_imm;
        alumux::s_imm: alumux2_out = s_imm;
        alumux::j_imm: alumux2_out = j_imm;
        alumux::rs2_out: alumux2_out = rs2_out;
        // etc.
    endcase

    unique case (regfilemux_sel)
        regfilemux::alu_out: regfilemux_out = alu_out;
        regfilemux::br_en: regfilemux_out = {31'b0, br_en};
        regfilemux::u_imm: regfilemux_out = u_imm;
        regfilemux::pc_plus4: regfilemux_out = pc_out + 32'h4;
        regfilemux::lw: regfilemux_out = mdrreg_out;
        regfilemux::lb: regfilemux_out = {{24{mdrreg_out[7 + 8 * alu_out[1:0]]}}, mdrreg_out[7 + 8 * alu_out[1:0] -: 8]};
        regfilemux::lh: regfilemux_out = {{16{mdrreg_out[15 + 8 * alu_out[1:0]]}}, mdrreg_out[(15 + alu_out[1:0]*8) -: 16]};
        regfilemux::lbu: regfilemux_out = {{24{1'b0}}, mdrreg_out[7 + 8 * alu_out[1:0] -: 8]};
        regfilemux::lhu: regfilemux_out = {{16{1'b0}}, mdrreg_out[(15 + alu_out[1:0]*8) -: 16]};
        // etc.
    endcase

    if(funct3 == rv32i_types::sb || funct3 == rv32i_types::sh) begin
        mem_data_out = (rs2_out << {alu_out[1:0], 3'd0});
    end
    else begin
        mem_data_out = rs2_out;
    end
    

    unique case (marmux_sel)
        marmux::pc_out: marmux_out = pc_out;
        marmux::alu_out: marmux_out = alu_out;
        // etc.
    endcase

    unique case (cmpmux_sel)
        cmpmux::rs2_out: cmp_mux_out = rs2_out;
        cmpmux::i_imm: cmp_mux_out = i_imm;
        // etc.
    endcase


end
/*****************************************************************************/
endmodule : datapath