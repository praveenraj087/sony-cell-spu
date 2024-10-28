module IF(clk, reset, ins_cache, pc, read_enable);

    input logic clk;
    input logic reset;
           
    input logic[0:31] ins_cache[0:255];  // Instruction line buffer , stores 64B instruction

    
    logic[0:31] instr_d[0:1];           // 2 instruction sent to DECODE stage
    logic stall;                        // incase of stall Instruction fetch 
                                        //should stop fetching new instruction
										
	logic branch_taken;

    output logic read_enable;           // Used to signal that IF is ready to read next set of 64B instruction

    output logic[7:0]   pc;
    
    logic[7:0]	pc_wb;                  // pc_wb access as reset PC signal for IF to start new instr read position
    integer pc_check;                // used for checkpointing, to adjust the pc while reading from ins_cache
	
	localparam [0:31] NOP = 32'b01000000001000000000000000000000;
	localparam [0:31] LNOP = 32'b00000000001000000000000000000000;

    Decode decode(clk, reset, instr_d, pc, pc_wb, stall, branch_taken);

    always_comb begin : pc_counter
        if(reset == 1) begin
            pc_check = 0;
            read_enable =1;
        end
        else begin
                read_enable = 0;
        end
    end

    always_ff @(posedge clk) begin : fetch_instruction
        
        $display($time," IF: stall %d pc %d pc_wb %d  read_enable %d ",stall, pc, pc_wb, read_enable);

        if(reset == 1 ) begin
            pc<=0;
            
            instr_d[0]<=32'h0000;
            instr_d[1]<=32'h0000;
            
        end
        else begin
            
         
            // Use of stall is to stop IF fetching new instruction 
            // This can be used in case of dual issue conflicts where decode
            // inserts no-op instruction 
            // we use pc_wb to continue fetch new stream of instruction then onwards
            
            if( stall==0 ) begin
                // stall<=0;
                instr_d[0]<=ins_cache[pc];
                instr_d[1]<=ins_cache[pc+1];
                $display($time," IF: ins %b ins %b pc %d pc_wb %d read_enable %d ",ins_cache[pc], ins_cache[pc+1],pc,pc_wb, read_enable);
                $display($time," IF: ins %h ins %h pc %d pc_wb %d read_enable %d ",ins_cache[pc], ins_cache[pc+1],pc,pc_wb, read_enable);


                $display($time," IF: ins %b ins %b pc %d pc_wb %d read_enable %d ",instr_d[0], instr_d[1],pc,pc_wb, read_enable);
                $display($time," IF: ins %h ins %h pc %d pc_wb %d read_enable %d ",instr_d[0], instr_d[1],pc,pc_wb, read_enable);

                if (pc < 254)
					pc <= pc+2;

                
            end
            else begin
				if (branch_taken == 0) begin
					$display($time,"IF: pc update to pc_wb %d pc %d" ,pc_wb, pc);
					instr_d[0]<=ins_cache[pc_wb];
					instr_d[1]<=ins_cache[pc_wb+1];
				end
				else begin
					pc <= pc_wb & ~1;
					$display($time,"IF: pc update to pc_wb %d pc %d" ,pc_wb, pc);
					if (pc_wb & 256'h1) begin				// If branching to an odd number instr
						instr_d[0]<=ins_cache[pc_wb-2];
						instr_d[1]<=0;
					end
					else begin
						instr_d[0]<=ins_cache[pc_wb-2];
						instr_d[1]<=ins_cache[pc_wb-1];
					end
				end
            end
        end
    end

endmodule