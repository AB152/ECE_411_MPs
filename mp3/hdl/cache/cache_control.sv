/* MODIFY. The cache controller. It is a state machine
that controls the behavior of the cache. */

module cache_control (
    input clk,
    input rst,
    input logic miss_overall,
    input logic dirty_overall,
    input logic hit_overall,
    input logic pmem_resp,
    input logic mem_read,
    input logic mem_write,
    output logic pmem_write,
    output logic pmem_read,
    // output logic write_cache,
    output logic data_in_sel,
    output logic write_back_state,
    output logic load_tag,
    output logic load_valid,
    output logic load_dirty,
    output logic load_data,
    output logic in_compare_tag
);
enum logic [3:0] {idle, compare_tag, allocate, write_back} curr_state, next_state; // States

always_ff @ (posedge clk) 
begin
        if (rst)
            curr_state <= idle;
        else
            curr_state <= next_state;
end


always_comb
    begin
        // next_state = curr_state;
        
        unique case (curr_state)
                    idle : if(mem_read ^ mem_write) begin
                                next_state = compare_tag;
                            end
                            else begin
                                next_state = idle;
                            end
                    
                    compare_tag : if(miss_overall && dirty_overall) begin
                                            next_state = write_back;
                                    end
                                    else if(miss_overall && dirty_overall == 0) begin
                                    next_state = allocate;
                                    end
                                    else if(hit_overall) begin
                                    next_state = idle;
                                    end
                                    else begin
                                    next_state = compare_tag;
                                    end

                    
                    write_back : if(pmem_resp == 0) begin
                                    next_state = write_back;
                                end
                                else begin
                                    next_state = allocate;
                                end

                    allocate : if(pmem_resp == 0) begin
                                        next_state = allocate;
                                   end
                                   else begin
                                        next_state = compare_tag;
                                   end
                    
                    // put_mem_into_cache : next_state = start;

                    default: next_state = idle;
            endcase

    end


always_comb
    begin
        case (curr_state)
                idle: 
                    begin
                        load_tag = 1'b0;
                        load_valid = 1'b0;
                        load_dirty = 1'b0;
                        load_data = 1'b0;
                        pmem_write = 1'b0;
                        pmem_read = 1'b0;
                        // write_cache = 1'b0;
                        data_in_sel = 1'b0;
                        write_back_state = 1'b0;
                        in_compare_tag = 1'b0;
                    end
                compare_tag:
                    begin
                        if(hit_overall) begin
                            load_tag = 1'b1;
                            load_valid = 1'b1;
                        end
                        else begin
                            load_tag = 1'b0;
                            load_valid = 1'b0;
                        end
                        if(mem_write) begin
                            load_dirty = 1'b1;
                        end
                        else begin
                            load_dirty = 1'b0;
                        end
                        if(mem_write && hit_overall) begin
                            load_data = 1'b1;
                        end
                        else begin
                            load_data = 1'b0;
                        end
                        // if hit
                        // set tag
                        // set valid
                        // if write
                        // set dirty
                        pmem_write = 1'b0;
                        pmem_read = 1'b0;
                        // write_cache = 1'b0;
                        data_in_sel = 1'b0;
                        write_back_state = 1'b0;
                        in_compare_tag = 1'b1;
                    end

                write_back: 
                    begin
                        load_tag = 1'b0;
                        load_valid = 1'b0;
                        load_dirty = 1'b0;
                        load_data = 1'b0;
                        pmem_write = 1'b1;
                        pmem_read = 1'b0;
                        // write_cache = 1'b0;
                        data_in_sel = 1'b0;
                        write_back_state = 1'b1;
                        in_compare_tag = 1'b0;
                    end
                allocate:
                    begin
                        // set tag
                        // set valid
                        load_tag = 1'b1;
                        load_valid = 1'b1;
                        load_dirty = 1'b0;
                        load_data = 1'b1;
                        pmem_write = 1'b0;
                        pmem_read = 1'b1;
                        // write_cache = 1'b1;
                        data_in_sel = 1'b1;
                        write_back_state = 1'b0;
                        in_compare_tag = 1'b0;
                    end

                default:
                    begin
                        load_tag = 1'b0;
                        load_valid = 1'b0;
                        load_dirty = 1'b0;
                        load_data = 1'b0;
                        pmem_write = 1'b0;
                        pmem_read = 1'b0;
                        // write_cache = 1'b0;
                        data_in_sel = 1'b0;
                        write_back_state = 1'b0;
                        in_compare_tag = 1'b0;
                    end
                
        endcase
    end

endmodule : cache_control























// /* MODIFY. The cache controller. It is a state machine
// that controls the behavior of the cache. */

// module cache_control (
//     input clk,
//     input rst,
//     input logic miss_overall,
//     input logic dirty_overall,
//     input logic hit_overall,
//     input logic pmem_resp,
//     input logic mem_read,
//     input logic mem_write,
//     output logic pmem_write,
//     output logic pmem_read,
//     output logic write_cache,
//     output logic data_in_sel,
//     output logic in_write_back_state
// );
// enum logic [3:0] {start, read_write_detected, write_mem, fetch_memory, put_mem_into_cache} curr_state, next_state; // States

// always_ff @ (posedge clk) 
// begin
//         if (rst)
//             curr_state <= start;
//         else
//             curr_state <= next_state;
// end


// always_comb
//     begin
//         // next_state = curr_state;
        
//         unique case (curr_state)
//                     start : if(mem_read ^ mem_write) begin
//                                 next_state = read_write_detected;
//                             end
//                             else begin
//                                 next_state = start;
//                             end
                    
//                     read_write_detected : if(miss_overall && dirty_overall) begin
//                                             next_state = write_mem;
//                                           end
//                                           else if(miss_overall && dirty_overall == 0) begin
//                                             next_state = fetch_memory;
//                                           end
//                                           else if(hit_overall) begin
//                                             next_state = start;
//                                           end
//                                           else begin
//                                             next_state = read_write_detected;
//                                           end

                    
//                     write_mem : if(pmem_resp == 0) begin
//                                     next_state = write_mem;
//                                 end
//                                 else begin
//                                     next_state = fetch_memory;
//                                 end

//                     fetch_memory : if(pmem_resp == 0) begin
//                                         next_state = fetch_memory;
//                                    end
//                                    else begin
//                                         // next_state = put_mem_into_cache;
//                                         next_state = start;
//                                    end
                    
//                     // put_mem_into_cache : next_state = start;

//                     default: next_state = start;


//             endcase

//     end


// always_comb
//     begin
//         case (curr_state)
//                 start: 
//                     begin
//                         pmem_write = 1'b0;
//                         pmem_read = 1'b0;
//                         write_cache = 1'b0;
//                         data_in_sel = 1'b0;
//                         in_write_back_state = 1'b0;
//                     end
//                 read_write_detected:
//                     begin
//                         pmem_write = 1'b0;
//                         pmem_read = 1'b0;
//                         write_cache = 1'b0;
//                         data_in_sel = 1'b0;
//                         in_write_back_state = 1'b0;
//                     end

//                 write_mem: 
//                     begin
//                         pmem_write = 1'b1;
//                         pmem_read = 1'b0;
//                         write_cache = 1'b0;
//                         data_in_sel = 1'b0;
//                         in_write_back_state = 1'b1;
//                     end
//                 fetch_memory:
//                     begin
//                         pmem_write = 1'b0;
//                         pmem_read = 1'b1;
                        
//                         write_cache = 1'b1;
//                         data_in_sel = 1'b1;
//                         in_write_back_state = 1'b0;
//                     end

//                 // put_mem_into_cache:
//                 //     begin
//                 //         pmem_write = 1'b0;
//                 //         pmem_read = 1'b0;
//                 //         write_cache = 1'b1;
//                 //         data_in_sel = 1'b1;
//                 //         in_write_back_state = 1'b0;
//                 //     end

//                 default:
//                     begin
//                         pmem_write = 1'b0;
//                         pmem_read = 1'b0;
//                         write_cache = 1'b0;
//                         data_in_sel = 1'b0;
//                         in_write_back_state = 1'b0;
//                     end
                
//         endcase
//     end

// endmodule : cache_control
