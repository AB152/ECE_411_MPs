module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);
    assign Reset = ~reset_n; // reset is active low
    logic[255:0] cacheline;

    enum logic [3:0] {reset, r1, r2, r3, r4, r5, w1, w2, w3, w4, w5} curr_state, next_state; // States

    always_ff @ (posedge clk) 
    begin
            if (Reset)
                curr_state <= reset;
            else
                curr_state <= next_state;
    end

    // Takes 4 cycles for read and write

    always_comb
		begin
            address_o = address_i; // output address is same as input according to testbench
            next_state = curr_state;
            
            unique case (curr_state)
						reset : if(read_i == 1)
									next_state = r1;
                                else if(write_i == 1)
									next_state = w1;
                                else
									next_state = reset;
                        
                        r1 : if(resp_i == 1)
                                next_state = r2;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = r1;

                        r2 : if(resp_i == 1)
                                next_state = r3;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = r2;
                        
                        r3 : if(resp_i == 1)
                                next_state = r4;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = r3;

                        r4 : if(resp_i == 1)
                                next_state = r5;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = r4;
                        
                        r5: next_state = reset;

                        w1 : if(resp_i == 1)
                                next_state = w2;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = w1;

                        w2 : if(resp_i == 1)
                                next_state = w3;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = w2;

                        w3 : if(resp_i == 1)
                                next_state = w4;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = w3;

                        w4 : if(resp_i == 1)
                                next_state = w5;
                             else if(Reset)
                                next_state = reset;
                             else
                                next_state = w4;

                        w5: next_state = reset;


				endcase

        end
    

    always_comb
		begin
            case (curr_state)
                    reset: 
                        begin
                            read_o = 0;
                            write_o = 0;
                            resp_o = 0;
                        end

                    r1: 
                        begin
                            read_o = 1;
                            write_o = 0;
                            resp_o = 0;
                            cacheline[64*0 +: 64] = burst_i;                              
                        end
                    r2:
                        begin
                            read_o = 1;
                            write_o = 0;
                            resp_o = 0;
                            cacheline[64*1 +: 64] = burst_i;
                        end

                    r3:
                        begin
                            read_o = 1;
                            write_o = 0;
                            resp_o = 0;
                            cacheline[64*2 +: 64] = burst_i;
                        end
                    
                    r4:
                        begin
                            read_o = 1;
                            write_o = 0;
                            resp_o = 0;
                            cacheline[64*3 +: 64] = burst_i;
                        end
                    
                    r5:
                        begin
                            read_o = 1;
                            write_o = 0;
                            resp_o = 1;
                            line_o = cacheline;
                        end


                    w1: 
                        begin
                            read_o = 0;
                            write_o = 1;
                            resp_o = 1;
                            burst_o = line_i[64*0 +: 64];                              
                        end
                    w2: 
                        begin
                            read_o = 0;
                            write_o = 1;
                            resp_o = 1;
                            burst_o = line_i[64*1 +: 64];                              
                        end

                    w3: 
                        begin
                            read_o = 0;
                            write_o = 1;
                            resp_o = 1;
                            burst_o = line_i[64*2 +: 64];                              
                        end

                    w4: 
                        begin
                            read_o = 0;
                            write_o = 1;
                            resp_o = 1;
                            burst_o = line_i[64*3 +: 64];                              
                        end
                    
                    w5: 
                        begin
                            read_o = 0;
                            write_o = 1;
                            resp_o = 1;
                        end
                    
            endcase
		end



endmodule : cacheline_adaptor
