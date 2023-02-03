
module cmp
import rv32i_types::*;
(
    input branch_funct3_t cmpop,
    input rv32i_word rs1_out,
	input rv32i_word cmp_mux_out,
    output logic br_en
);

always_comb
begin
    case (cmpop)
        rv32i_types::beq:  br_en = $signed(rs1_out) == $signed(cmp_mux_out) ? 1 : 0;
        rv32i_types::bne:  br_en = $signed(rs1_out) != $signed(cmp_mux_out) ? 1 : 0;
        rv32i_types::blt:  br_en = $signed(rs1_out) < $signed(cmp_mux_out) ? 1 : 0;
        rv32i_types::bge:  br_en = $signed(rs1_out) >= $signed(cmp_mux_out) ? 1 : 0;
        rv32i_types::bltu: br_en = rs1_out < cmp_mux_out ? 1 : 0;
        rv32i_types::bgeu: br_en = rs1_out >= cmp_mux_out ? 1 : 0;
    endcase
end

endmodule : cmp
