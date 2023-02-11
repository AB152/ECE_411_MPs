module control
import rv32i_types::*; /* Import types defined in rv32i_types.sv */
(
    input clk,
    input rst,
    input rv32i_opcode opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,
    input logic br_en,
    input logic [4:0] rs1,
    input logic [4:0] rs2,
    input logic mem_resp,
    input logic [31:0] alu_out,
    output pcmux::pcmux_sel_t pcmux_sel,
    output alumux::alumux1_sel_t alumux1_sel,
    output alumux::alumux2_sel_t alumux2_sel,
    output regfilemux::regfilemux_sel_t regfilemux_sel,
    output marmux::marmux_sel_t marmux_sel,
    output cmpmux::cmpmux_sel_t cmpmux_sel,
    output alu_ops aluop,
    output logic load_pc,
    output logic load_ir,
    output logic load_regfile,
    output logic load_mar,
    output logic load_mdr,
    output logic load_data_out,
    // Extra Signals
    output logic mem_write,
    output logic mem_read,
    output branch_funct3_t cmpop,
    output logic [3:0] mem_byte_enable
);

/***************** USED BY RVFIMON --- ONLY MODIFY WHEN TOLD *****************/
logic trap;
logic [4:0] rs1_addr, rs2_addr;
logic [3:0] rmask, wmask;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(funct3);
assign branch_funct3 = branch_funct3_t'(funct3);
assign load_funct3 = load_funct3_t'(funct3);
assign store_funct3 = store_funct3_t'(funct3);
assign rs1_addr = rs1;
assign rs2_addr = rs2;

always_comb
begin : trap_check
    trap = '0;
    rmask = '0;
    wmask = '0;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = '1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh, lhu: rmask = 4'b0011 << alu_out[1:0] /* Modify for MP1 Final */ ;
                lb, lbu: rmask = 4'b0001 << alu_out[1:0] /* Modify for MP1 Final */ ;
                default: trap = '1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh: wmask = 4'b0011 << alu_out[1:0] /* Modify for MP1 Final */ ;
                sb: wmask = 4'b0001 << alu_out[1:0] /* Modify for MP1 Final */ ;
                default: trap = '1;
            endcase
        end

        default: trap = '1;
    endcase
end
/*****************************************************************************/

enum int unsigned {
    /* List of states */
    fetch1,
    fetch2,
    fetch3,
    decode,
    imm,
    lui,
    calc_addr_load,
    calc_addr_store,
    auipc,
    br,
    ld1,
    st1,
    ld2,
    st2,
    jal,
    jalr,
    rtor
} state, next_state;

/************************* Function Definitions *******************************/
/**
 *  You do not need to use these functions, but it can be nice to encapsulate
 *  behavior in such a way.  For example, if you use the `loadRegfile`
 *  function, then you only need to ensure that you set the load_regfile bit
 *  to 1'b1 in one place, rather than in many.
 *
 *  SystemVerilog functions must take zero "simulation time" (as opposed to 
 *  tasks).  Thus, they are generally synthesizable, and appropraite
 *  for design code.  Arguments to functions are, by default, input.  But
 *  may be passed as outputs, inouts, or by reference using the `ref` keyword.
**/

/**
 *  Rather than filling up an always_block with a whole bunch of default values,
 *  set the default values for controller output signals in this function,
 *   and then call it at the beginning of your always_comb block.
**/
function void set_defaults();
    load_pc = 1'b0;
    load_ir = 1'b0;
    load_regfile = 1'b0;
    load_mar = 1'b0;
    load_mdr = 1'b0;
    load_data_out = 1'b0;
    pcmux_sel = pcmux::pc_plus4;
    cmpop = rv32i_types::branch_funct3_t '(funct3);
    alumux1_sel = alumux::rs1_out;
    alumux2_sel = alumux::i_imm;
    regfilemux_sel = regfilemux::alu_out;
    marmux_sel = marmux::pc_out;
    cmpmux_sel = cmpmux::rs2_out;
    aluop = rv32i_types::alu_ops '(funct3);
    mem_read = 1'b0;
    mem_write = 1'b0;
    mem_byte_enable = 4'b1111;
endfunction

/**
 *  Use the next several functions to set the signals needed to
 *  load various registers
**/
// function void loadPC(pcmux::pcmux_sel_t sel);
//     load_pc = 1'b1;
//     pcmux_sel = sel;
// endfunction

// function void loadRegfile(regfilemux::regfilemux_sel_t sel);
// endfunction

// function void loadMAR(marmux::marmux_sel_t sel);
// endfunction

// function void loadMDR();
// endfunction

// function void setALU(alumux::alumux1_sel_t sel1, alumux::alumux2_sel_t sel2, logic setop, alu_ops op);
//     /* Student code here */


//     if (setop)
//         aluop = op; // else default value
// endfunction

// function automatic void setCMP(cmpmux::cmpmux_sel_t sel, branch_funct3_t op);
// endfunction

/*****************************************************************************/

    /* Remember to deal with rst signal */

always_comb
begin : state_actions
    /* Default output assignments */
    set_defaults();
    if(state == fetch1) begin
        load_mar = 1;
    end
    else if(state == fetch2) begin
        load_mdr = 1;
        mem_read = 1;
    end
    else if(state == fetch3) begin
        load_ir = 1;
    end
    else if(state == decode) begin
    end
    else if(state == imm) begin
        load_regfile = 1;
        load_pc = 1;

        if(funct3 == rv32i_types::slt) begin
            // SLTI
            cmpop = rv32i_types::blt;
            regfilemux_sel = regfilemux::br_en;
            cmpmux_sel = cmpmux::i_imm;
            // rs1_addr = rs1;
        end
        else if(funct3 == rv32i_types::sltu) begin
            // SLTIU
            cmpop = rv32i_types::bltu;
            regfilemux_sel = regfilemux::br_en;
            cmpmux_sel = cmpmux::i_imm;
            // rs1_addr = rs1;
        end
        else if(funct3 == rv32i_types::sr) begin
            // SRAI
            unique case (funct7)
                7'b0100000: aluop = rv32i_types::alu_sra;
                default: aluop = rv32i_types::alu_srl;
            endcase
            // rs1_addr = rs1;
            //regfile mux is default alu_out
        end
        else begin
            // All other I instructions
            aluop = rv32i_types::alu_ops'(funct3);
            // rs1_addr = rs1;
        end
    end
    else if(state == lui) begin
        load_regfile = 1;
        load_pc = 1;
        regfilemux_sel = regfilemux::u_imm;
        // rs1_addr = rs1;
    end
    // Split calc_addr into two states
    else if(state == calc_addr_load) begin
        aluop = rv32i_types::alu_add;
        load_mar = 1;
        marmux_sel = marmux::alu_out;
    end
    else if(state == calc_addr_store) begin
        aluop = rv32i_types::alu_add;
        load_mar = 1;
        load_data_out = 1;
        alumux2_sel = alumux::s_imm;
        marmux_sel = marmux::alu_out;
    end
    else if(state == auipc) begin
        alumux1_sel = alumux::pc_out;
        alumux2_sel = alumux::u_imm;
        load_regfile = 1;
        load_pc = 1;
        aluop = rv32i_types::alu_add;
    end
    else if(state == br) begin
        pcmux_sel = pcmux::pcmux_sel_t '({1'b0,br_en});
        load_pc = 1;
        alumux1_sel = alumux::pc_out;
        alumux2_sel = alumux::b_imm;
        aluop = rv32i_types::alu_add;
		cmpop = branch_funct3_t '(funct3);
        // rs1_addr = rs1;
        // rs2_addr = rs2;
    end
    else if(state == ld1) begin
        load_mdr = 1;
        mem_read = 1;
        aluop = rv32i_types::alu_add;
        marmux_sel = marmux::alu_out;
    end
    else if(state == st1) begin
        mem_write = 1;
        aluop = rv32i_types::alu_add;
        alumux2_sel = alumux::s_imm;
        marmux_sel = marmux::alu_out;
        case(funct3)
            rv32i_types::sb: mem_byte_enable = 4'h1 << alu_out[1:0];
            rv32i_types::sh: mem_byte_enable = 4'b0011 << alu_out[1:0];
            default: mem_byte_enable = 4'hF;
        endcase
    end
    else if(state == ld2) begin
        load_regfile = 1;
        load_pc = 1;
        aluop = rv32i_types::alu_add;
        marmux_sel = marmux::alu_out;
        // regfilemux_sel = regfilemux::lw;
        case(funct3)
            rv32i_types::lw: regfilemux_sel = regfilemux::lw;
            rv32i_types::lb: regfilemux_sel = regfilemux::lb;
            rv32i_types::lh: regfilemux_sel = regfilemux::lh;
            rv32i_types::lbu: regfilemux_sel = regfilemux::lbu;
            rv32i_types::lhu: regfilemux_sel = regfilemux::lhu;
        endcase
        // rs1_addr = rs1;
    end
    else if(state == st2) begin
        load_pc = 1;
        aluop = rv32i_types::alu_add;
        alumux2_sel = alumux::s_imm;
        marmux_sel = marmux::alu_out;
        // rs1_addr = rs1;
        // rs2_addr = rs2;
    end
    else if(state == jal) begin
        alumux2_sel = alumux::j_imm;
        alumux1_sel = alumux::pc_out;
        aluop = rv32i_types::alu_add;
        pcmux_sel = pcmux::alu_out;
        load_pc = 1;

        regfilemux_sel = regfilemux::pc_plus4;
        load_regfile = 1;

    end
    else if(state == jalr) begin
        alumux2_sel = alumux::i_imm;
        alumux1_sel = alumux::rs1_out;
        aluop = rv32i_types::alu_add;
        pcmux_sel = pcmux::alu_mod2;
        load_pc = 1;

        regfilemux_sel = regfilemux::pc_plus4;
        load_regfile = 1;
    end
    else if(state == rtor) begin
        load_pc = 1;
        load_regfile = 1;
        alumux2_sel = alumux::rs2_out;
        regfilemux_sel = regfilemux::alu_out;

        if(funct3 == rv32i_types::add && funct7[5] == 0) begin
            aluop = alu_add;
        end
        else if(funct3 == rv32i_types::add && funct7[5] == 1) begin
            aluop = alu_sub;
        end
        else if(funct3 == rv32i_types::sll) begin
            aluop = alu_sll;
        end
        else if(funct3 == rv32i_types::slt) begin
            cmpop = blt;
            cmpmux_sel = cmpmux::rs2_out;
            regfilemux_sel = regfilemux::br_en;
        end
        else if(funct3 == rv32i_types::sltu) begin
            cmpop = bltu;
            cmpmux_sel = cmpmux::rs2_out;
            regfilemux_sel = regfilemux::br_en;
        end
        else if(funct3 == rv32i_types::axor) begin
            aluop = alu_xor;
        end
        else if(funct3 == rv32i_types::sr && funct7[5] == 0) begin
            aluop = alu_srl;
        end
        else if(funct3 == rv32i_types::sr && funct7[5] == 1) begin
            aluop = alu_sra;
        end
        else if(funct3 == rv32i_types::aor) begin
            aluop = alu_or;
        end
        else if(funct3 == rv32i_types::aand) begin
            aluop = alu_and;
        end
        else begin
            // Default case
        end
    end



    /* Actions for each state */
end

always_comb
begin : next_state_logic
    /* Next state information and conditions (if any)
     * for transitioning between states */
    if(rst) begin
        next_state = fetch1;
    end
    else if(state == fetch1) begin
        next_state = fetch2;
    end
    else if(state == fetch2 && mem_resp == 0) begin
        next_state = fetch2;
    end
    else if(state == fetch2) begin
        next_state = fetch3;
    end
    else if(state == fetch3) begin
        next_state = decode;
    end
    else if(state == decode) begin
        unique case (opcode)
            rv32i_types::op_auipc: next_state = auipc;
            rv32i_types::op_load: next_state = calc_addr_load;
            rv32i_types::op_lui: next_state = lui;
            rv32i_types::op_imm: next_state = imm;
            rv32i_types::op_br: next_state = br;
            rv32i_types::op_store: next_state = calc_addr_store;
            rv32i_types::op_jal: next_state = jal;
            rv32i_types::op_jalr: next_state = jalr;
            rv32i_types::op_reg: next_state = rtor;
            default: next_state = fetch1;
        endcase
    end
    else if(state == imm) begin
        next_state = fetch1;
    end
    else if(state == lui) begin
        next_state = fetch1;
    end
    else if(state == auipc) begin
        next_state = fetch1;
    end
    else if(state == br) begin
        next_state = fetch1;
    end
    else if(state == lui) begin
        next_state = fetch1;
    end
    else if(state == calc_addr_load) begin
        next_state = ld1;
    end
    else if(state == ld1 && mem_resp == 0) begin
        next_state = ld1;
    end
    else if(state == ld1) begin
        next_state = ld2;
    end
    else if(state == ld2) begin
        next_state = fetch1;
    end
    else if(state == calc_addr_store) begin
        next_state = st1;
    end
    else if(state == st1 && mem_resp == 0) begin
        next_state = st1;
    end
    else if(state == st1) begin
        next_state = st2;
    end
    else if(state == st2) begin
        next_state = fetch1;
    end
    else if(state == jal) begin
        next_state = fetch1;
    end
    else if(state == jalr) begin
        next_state = fetch1;
    end
    else if(state == rtor) begin
        next_state = fetch1;
    end
    else begin
        next_state = fetch1;
    end
end

always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state <= next_state;
end

endmodule : control