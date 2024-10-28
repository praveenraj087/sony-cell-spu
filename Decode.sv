module Decode(clk, reset, instr, pc, stall_pc, stall, branch_taken_reg);
    input logic			clk, reset;
    input logic [0:31] 	instr[0:1];
	logic [0:31] 		instr_next[0:1], instr_dec[0:1], instr_next_reg[0:1];

	logic [0:31]	instr_even, instr_odd, instr_odd_issue, instr_even_issue;	//Instr from decoder
	
	//Signals for handling branches
	logic [7:0]			pc_wb;									//New program counter for branch
	output logic [7:0]	stall_pc;
	output logic 		stall;
	output logic		branch_taken_reg;							//Was branch taken?
	logic				branch_taken;								//Was branch taken?
	logic				first_odd, first_odd_out;				//1 if odd instr is first in pair, 0 else; Used for branch flushing
	logic			 	stall_var;
	logic [7:0]			stall_pc_var;

    input logic[7:0] pc;                           // PC for the current state

    //Nets from decode logic
	logic [2:0]		format_even, format_odd;				//Format of instr
	logic [0:10]	op_even, op_odd;						//Opcode of instr (used with format)
	logic [1:0]		unit_even, unit_odd;					//Destination unit of instr; Order of: FP, FX2, Byte, FX1 (Even); Perm, LS, Br (Odd)
	logic [0:6]		rt_addr_even, rt_addr_odd;				//Destination register addresses
	logic [0:17]	imm_even, imm_odd;						//Full possible immediate value (used with format)
	logic			reg_write_even, reg_write_odd;			//1 if instr will write to rt, else 0
	
	logic			first_cyc;								//Due to how finished is detected, workaround is needed to prevent flag after reset
	
	logic [7:0]		pc_dec, pc_pipe;									//New program counter for stalls
	
	localparam [0:31] NOP = 32'b01000000001000000000000000000000;
	localparam [0:31] LNOP = 32'b00000000001000000000000000000000;
	
	//Internal Signals for Handling RAW Hazards
	logic [0:6]			rt_addr_delay_even, rt_addr_delay_odd;		//Destination register for rt_wb
	logic				reg_write_delay_even, reg_write_delay_odd;	//Will rt_wb write to RegTable
	logic 				stall_first_raw, stall_second_raw;			// 1 if respective signal is to be stalled due to RAW hazard
	logic 				stall_first, stall_second;			// 1 if respective signal is to be stalled due to RAW or structural hazard
	
	logic [6:0][0:6]	rt_addr_delay_fp1;		//Destination register for rt_wb
	logic [6:0]			reg_write_delay_fp1;	//Will rt_wb write to RegTable
	logic [6:0]			int_delay_fp1;			//Will fp1 write an int result
	
	logic [3:0][0:6]	rt_addr_delay_fx2;		//Destination register for rt_wb
	logic [3:0]			reg_write_delay_fx2;	//Will rt_wb write to RegTable
	
	logic [3:0][0:6]	rt_addr_delay_b1;		//Destination register for rt_wb
	logic [3:0]			reg_write_delay_b1;		//Will rt_wb write to RegTable
	
	logic [1:0][0:6]	rt_addr_delay_fx1;		//Destination register for rt_wb
	logic [1:0]			reg_write_delay_fx1;	//Will rt_wb write to RegTable
	
	logic [3:0][0:6]	rt_addr_delay_p1;		//Destination register for rt_wb
	logic [3:0]			reg_write_delay_p1;		//Will rt_wb write to RegTable
	
	logic [5:0][0:6]	rt_addr_delay_ls1;		//Destination register for rt_wb
	logic [5:0]			reg_write_delay_ls1;	//Will rt_wb write to RegTable
		
	typedef struct { 
		logic [0:31]	instr;	
		logic [0:10]	op;
		logic			reg_write;
		logic			even_valid, odd_valid;			//Is even/odd instr a valid instr?
		logic [0:17]	imm;	
		logic [0:6]		rt_addr;	
		logic [1:0]		unit;	
		logic [2:0]		format;
		logic [0:6]		ra_addr, rb_addr, rc_addr;
		logic			ra_valid, rb_valid, rc_valid;	//Is ra/rb/rc read in this instr?
	} op_code;
	
	op_code first, second;

    Pipes pipe(.clk(clk), .reset(reset), .pc(pc_pipe),
		.instr_even(instr_even), .instr_odd(instr_odd),
		.pc_wb(pc_wb), .branch_taken(branch_taken),
        .op_even(op_even), .op_odd(op_odd),
        .unit_even(unit_even), .unit_odd(unit_odd),
        .rt_addr_even(rt_addr_even), .rt_addr_odd(rt_addr_odd),
        .format_even(format_even), .format_odd(format_odd),
        .imm_even(imm_even), .imm_odd(imm_odd),
        .reg_write_even(reg_write_even), .reg_write_odd(reg_write_odd), .first_odd(first_odd_out), 
		.rt_addr_delay_even(rt_addr_delay_even), .reg_write_delay_even(reg_write_delay_even), .rt_addr_delay_odd(rt_addr_delay_odd), .reg_write_delay_odd(reg_write_delay_odd),
		.rt_addr_delay_fp1(rt_addr_delay_fp1), .reg_write_delay_fp1(reg_write_delay_fp1), .int_delay_fp1(int_delay_fp1), .rt_addr_delay_fx2(rt_addr_delay_fx2), .reg_write_delay_fx2(reg_write_delay_fx2),
		.rt_addr_delay_b1(rt_addr_delay_b1), .reg_write_delay_b1(reg_write_delay_b1), .rt_addr_delay_fx1(rt_addr_delay_fx1), .reg_write_delay_fx1(reg_write_delay_fx1),
		.rt_addr_delay_p1(rt_addr_delay_p1), .reg_write_delay_p1(reg_write_delay_p1), .rt_addr_delay_ls1(rt_addr_delay_ls1), .reg_write_delay_ls1(reg_write_delay_ls1)
        );

	always_ff @( posedge clk ) begin : decode_op
	
		if (first.even_valid) begin
			instr_even <= first.instr;
			op_even <= first.op;
			reg_write_even <= first.reg_write;
			imm_even <= first.imm;
			rt_addr_even <= first.rt_addr;
			unit_even <= first.unit;
			format_even <= first.format;
			first_odd_out <= 0;
		end
		else if (second.even_valid) begin
			instr_even <= second.instr;
			op_even <= second.op;
			reg_write_even <= second.reg_write;
			imm_even <= second.imm;
			rt_addr_even <= second.rt_addr;
			unit_even <= second.unit;
			format_even <= second.format;
		end
		else begin
			instr_even <= 0;
			op_even <= 0;
			reg_write_even <= 0;
			imm_even <= 0;
			rt_addr_even <= 0;
			unit_even <= 0;
			format_even <= 0;
		end
		
		if (first.odd_valid) begin
			instr_odd <= first.instr;
			op_odd <= first.op;
			reg_write_odd <= first.reg_write;
			imm_odd <= first.imm;
			rt_addr_odd <= first.rt_addr;
			unit_odd <= first.unit;
			format_odd <= first.format;
			first_odd_out <= 1;
		end
		else if (second.odd_valid) begin
			instr_odd <= second.instr;
			op_odd <= second.op;
			reg_write_odd <= second.reg_write;
			imm_odd <= second.imm;
			rt_addr_odd <= second.rt_addr;
			unit_odd <= second.unit;
			format_odd <= second.format;
			first_odd_out <= 0;
		end
		else begin
			instr_odd <= 0;
			op_odd <= 0;
			reg_write_odd <= 0;
			imm_odd <= 0;
			rt_addr_odd <= 0;
			unit_odd <= 0;
			format_odd <= 0;
		end
		
		instr_next_reg <= instr_next;
		stall <= stall_var;
		stall_pc <= stall_pc_var;
		branch_taken_reg <= branch_taken;
		pc_pipe <= pc_dec;
		
		first_cyc <= reset;		//flag is always high after reset and low otherwise
	end
	
	
	//Decode logic
	always_comb begin
		
		stall_first = 0;
		stall_second = 0;
	
		$display("=======================================");
		$display($time," New Decode: Sensitivity list");
		$display("pc: %d, reset: %b, branch_taken: %b, finished: %b, stall: %b", pc, reset, branch_taken, 0, stall);
		$display("instr_next[0]: 		%b, instr_next[1]: 		%b, ", instr_next[0], instr_next[1]);
		$display("instr_next_reg[0]: 	%b, instr_next_reg[1]: 	%b, ", instr_next_reg[0], instr_next_reg[1]);
		$display("instr[0]:      		%b, instr[1]:      		%b", instr[0], instr[1]);
		$display("=======================================");
		
		if (reset == 1) begin
			stall_var = 0;
			stall_pc_var = 0;
			first_odd = 0;
			first = check_one(0);
			second = check_one(0);
			instr_next[0] = 0;
			instr_next[1] = 0;
		end
		else begin
			if (branch_taken == 1) begin
				$display($time," New Decode: Branch taken, jumping to addr: %d", pc_wb);
				stall_pc_var = pc_wb+2;
				stall_var = 1;
				instr_next[0] = 0;
				instr_next[1] = 0;
				first = check_one(0);
				second = check_one(0);
			end
			else begin
				if (stall == 1) begin
					instr_dec[0] = instr_next_reg[0];
					instr_dec[1] = instr_next_reg[1];
					stall_var = 0;
					pc_dec = stall_pc;
					$display($time," New Decode: Choosing queued instr");
				end
				else begin
					instr_dec[0] = instr[0];
					instr_dec[1] = instr[1];
					pc_dec = pc;
					$display($time," New Decode: Choosing new instr");
				end
				
				if ((instr_dec[0] != 0)) begin
					first = check_one(instr_dec[0]);	//Checking first instr
					
					if (first.ra_valid) begin
						for (int i = 0; i <= 4; i++) begin
							if ((first.ra_addr == rt_addr_delay_fp1[i]) && (reg_write_delay_fp1[i] && int_delay_fp1[i])) begin
								stall_first = 1;
							end
							
							if ((i < 4) &&
								(((first.ra_addr == rt_addr_delay_ls1[i]) && reg_write_delay_ls1[i]) ||
								((first.ra_addr == rt_addr_delay_fp1[i]) && reg_write_delay_fp1[i]))) begin
								stall_first = 1;
							end
							
							if ((i < 2) &&
								(((first.ra_addr == rt_addr_delay_fx2[i]) && reg_write_delay_fx2[i]) ||
								((first.ra_addr == rt_addr_delay_b1[i]) && reg_write_delay_b1[i]) ||
								((first.ra_addr == rt_addr_delay_p1[i]) && reg_write_delay_p1[i]))) begin
								stall_first = 1;
							end
						end
						if ((first.ra_addr == rt_addr_delay_even) && reg_write_delay_even) begin
							stall_first = 1;
						end
						if ((first.ra_addr == rt_addr_delay_odd) && reg_write_delay_odd) begin
							stall_first = 1;
						end
					end
					if (first.rb_valid) begin
						for (int i = 0; i <= 4; i++) begin
							if ((first.rb_addr == rt_addr_delay_fp1[i]) && (reg_write_delay_fp1[i] && int_delay_fp1[i])) begin
								stall_first = 1;
							end
							
							if ((i < 4) &&
								(((first.rb_addr == rt_addr_delay_ls1[i]) && reg_write_delay_ls1[i]) ||
								((first.rb_addr == rt_addr_delay_fp1[i]) && reg_write_delay_fp1[i]))) begin
								stall_first = 1;
							end
							
							if ((i < 2) &&
								(((first.rb_addr == rt_addr_delay_fx2[i]) && reg_write_delay_fx2[i]) ||
								((first.rb_addr == rt_addr_delay_b1[i]) && reg_write_delay_b1[i]) ||
								((first.rb_addr == rt_addr_delay_p1[i]) && reg_write_delay_p1[i]))) begin
								stall_first = 1;
							end
						end
						if ((first.rb_addr == rt_addr_delay_even) && reg_write_delay_even) begin
							stall_first = 1;
						end
						if ((first.rb_addr == rt_addr_delay_odd) && reg_write_delay_odd) begin
							stall_first = 1;
						end
					end
					if (first.rc_valid) begin
						for (int i = 0; i <= 4; i++) begin
							if ((first.rc_addr == rt_addr_delay_fp1[i]) && (reg_write_delay_fp1[i] && int_delay_fp1[i])) begin
								stall_first = 1;
							end
							
							if ((i < 4) &&
								(((first.rc_addr == rt_addr_delay_ls1[i]) && reg_write_delay_ls1[i]) ||
								((first.rc_addr == rt_addr_delay_fp1[i]) && reg_write_delay_fp1[i]))) begin
								stall_first = 1;
							end
							
							if ((i < 2) &&
								(((first.rc_addr == rt_addr_delay_fx2[i]) && reg_write_delay_fx2[i]) ||
								((first.rc_addr == rt_addr_delay_b1[i]) && reg_write_delay_b1[i]) ||
								((first.rc_addr == rt_addr_delay_p1[i]) && reg_write_delay_p1[i]))) begin
								stall_first = 1;
							end
						end
						if ((first.rc_addr == rt_addr_delay_even) && reg_write_delay_even) begin
							stall_first = 1;
						end
						if ((first.rc_addr == rt_addr_delay_odd) && reg_write_delay_odd) begin
							stall_first = 1;
						end
					end
				end
				else begin
					first = check_one(0);
				end
				
				if ((instr_dec[1] != 0)) begin
					second = check_one(instr_dec[1]);
					
					if ((second.even_valid && first.even_valid) || (second.odd_valid && first.odd_valid)) begin		//Same pipe, structural hazard
						stall_second = 1;
						$display($time," New Decode: Same pipe hazard found for second instr");
					end
					else if (first.reg_write && second.reg_write && (first.rt_addr == second.rt_addr)) begin			//Same dest, data hazard (WAW)
						stall_second = 1;
						$display($time," New Decode: Same destination hazard found for second instr");
					end
					else begin
						if (second.ra_valid) begin
							for (int i = 0; i <= 4; i++) begin
								if ((second.ra_addr == rt_addr_delay_fp1[i]) && (reg_write_delay_fp1[i] && int_delay_fp1[i])) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr ra");
								end
								
								if ((i < 4) &&
									(((second.ra_addr == rt_addr_delay_ls1[i]) && reg_write_delay_ls1[i]) ||
									((second.ra_addr == rt_addr_delay_fp1[i]) && reg_write_delay_fp1[i]))) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr ra");
								end
								
								if ((i < 2) &&
									(((second.ra_addr == rt_addr_delay_fx2[i]) && reg_write_delay_fx2[i]) ||
									((second.ra_addr == rt_addr_delay_b1[i]) && reg_write_delay_b1[i]) ||
									((second.ra_addr == rt_addr_delay_p1[i]) && reg_write_delay_p1[i]))) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr ra");
								end
							end
							if ((second.ra_addr == rt_addr_delay_even) && reg_write_delay_even) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr ra");
							end
							if ((second.ra_addr == rt_addr_delay_odd) && reg_write_delay_odd) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr ra");
							end
							if ((second.ra_addr == first.rt_addr) && first.reg_write) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr ra");
							end
						end
						if (second.rb_valid) begin
							for (int i = 0; i <= 4; i++) begin
								if ((second.rb_addr == rt_addr_delay_fp1[i]) && (reg_write_delay_fp1[i] && int_delay_fp1[i])) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr rb");
								end
								
								if ((i < 4) &&
									(((second.rb_addr == rt_addr_delay_ls1[i]) && reg_write_delay_ls1[i]) ||
									((second.rb_addr == rt_addr_delay_fp1[i]) && reg_write_delay_fp1[i]))) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr rb");
								end
								
								if ((i < 2) &&
									(((second.rb_addr == rt_addr_delay_fx2[i]) && reg_write_delay_fx2[i]) ||
									((second.rb_addr == rt_addr_delay_b1[i]) && reg_write_delay_b1[i]) ||
									((second.rb_addr == rt_addr_delay_p1[i]) && reg_write_delay_p1[i]))) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr rb");
								end
							end
							if ((second.rb_addr == rt_addr_delay_even) && reg_write_delay_even) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr rb");
							end
							if ((second.rb_addr == rt_addr_delay_odd) && reg_write_delay_odd) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr rb");
							end
							if ((second.rb_addr == first.rt_addr) && first.reg_write) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr rb");
							end
						end
						if (second.rc_valid) begin
							for (int i = 0; i <= 4; i++) begin
								if ((second.rc_addr == rt_addr_delay_fp1[i]) && (reg_write_delay_fp1[i] && int_delay_fp1[i])) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr rc");
								end
								
								if ((i < 4) &&
									(((second.rc_addr == rt_addr_delay_ls1[i]) && reg_write_delay_ls1[i]) ||
									((second.rc_addr == rt_addr_delay_fp1[i]) && reg_write_delay_fp1[i]))) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr rc");
								end
								
								if ((i < 2) &&
									(((second.rc_addr == rt_addr_delay_fx2[i]) && reg_write_delay_fx2[i]) ||
									((second.rc_addr == rt_addr_delay_b1[i]) && reg_write_delay_b1[i]) ||
									((second.rc_addr == rt_addr_delay_p1[i]) && reg_write_delay_p1[i]))) begin
									stall_second = 1;
									$display($time," New Decode: RAW hazard found for second instr rc");
								end
							end
							if ((second.rc_addr == rt_addr_delay_even) && reg_write_delay_even) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr rc");
							end
							if ((second.rc_addr == rt_addr_delay_odd) && reg_write_delay_odd) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr rc");
							end
							if ((second.rc_addr == first.rt_addr) && first.reg_write) begin
								stall_second = 1;
								$display($time," New Decode: RAW hazard found for second instr rc");
							end
						end
					end
				end
				else begin
					second = check_one(0);
				end
				
				if (stall_first) begin
					$display($time," New Decode: RAW hazard found for first instr");
					stall_pc_var = pc_dec;
					stall_var = 1;
					instr_next[0] = instr_dec[0];
					instr_next[1] = instr_dec[1];
					first = check_one(0);
					second = check_one(0);
				end
				else if (stall_second) begin
					stall_pc_var = pc_dec;
					stall_var = 1;
					instr_next[0] = 0;
					instr_next[1] = instr_dec[1];
					second = check_one(0);
				end
				else begin
					stall_var = 0;
				end
			end
			
			$display($time, "finished_var: %b, stall_var: %b", 0, stall_var);
		end
	

	end

	function op_code check_one (input logic[0:31] instr);

		if(reset==1) begin
			check_one.op = 0;
			check_one.even_valid = 1;
			check_one.odd_valid = 1;
		end
		$display($time," instr %b %b",instr, instr[0:10]);
															//Even decoding
		check_one.reg_write = 1;
		check_one.rt_addr = instr[25:31];
		check_one.ra_addr = instr[18:24];
		check_one.rb_addr = instr[11:17];
		check_one.rc_addr = instr[25:31];
		check_one.instr = instr;
		check_one.even_valid = 1;
		if (instr == 0) begin							//alternate nop
			check_one.format = 0;
			check_one.ra_valid = 0;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 0;
			check_one.unit = 0;
			check_one.rt_addr = 0;
			check_one.imm = 0;
			check_one.reg_write = 0;
			check_one.even_valid = 0;
		end													//RRR-type
		else if	(instr[0:3] == 4'b1100) begin			//mpya
			check_one.format = 1;
			check_one.ra_valid = 1;
			check_one.rb_valid = 1;
			check_one.rc_valid = 1;
			check_one.op = 4'b1100;
			check_one.unit = 0;
			check_one.rt_addr = instr[4:10];
		end
		else if (instr[0:3] == 4'b1110) begin			//fma
			check_one.format = 1;
			check_one.ra_valid = 1;
			check_one.rb_valid = 1;
			check_one.rc_valid = 1;
			check_one.op = 4'b1110;
			check_one.unit = 0;
			check_one.rt_addr = instr[4:10];
		end
		else if (instr[0:3] == 4'b1111) begin			//fms
			check_one.format = 1;
			check_one.ra_valid = 1;
			check_one.rb_valid = 1;
			check_one.rc_valid = 1;
			check_one.op = 4'b1111;
			check_one.unit = 0;
			check_one.rt_addr = instr[4:10];
		end													//RI18-type
		else if (instr[0:6] == 7'b0100001) begin		//ila
			check_one.format = 6;
			check_one.ra_valid = 0;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 7'b0100001;
			check_one.unit = 3;
			check_one.imm = $signed(instr[7:24]);
		end													//RI8-type
		else if (instr[0:9] == 10'b0111011000) begin	//cflts
			check_one.format = 3;
			check_one.ra_valid = 1;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 10'b0111011000;
			check_one.unit = 0;
			check_one.imm = $signed(instr[10:17]);
		end
		else if (instr[0:9] == 10'b0111011001) begin	//cfltu
			check_one.format = 3;
			check_one.ra_valid = 1;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 10'b0111011001;
			check_one.unit = 0;
			check_one.imm = $signed(instr[10:17]);
		end													//RI16-type
		else if (instr[0:8] == 9'b010000011) begin		//ilh
			check_one.format = 5;
			check_one.ra_valid = 0;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 9'b010000011;
			check_one.unit = 3;
			check_one.imm = $signed(instr[9:24]);
		end
		else if (instr[0:8] == 9'b010000001) begin		//il
			check_one.format = 5;
			check_one.ra_valid = 0;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 9'b010000001;
			check_one.unit = 3;
			check_one.imm = $signed(instr[9:24]);
		end
		else if (instr[0:8] == 9'b010000010) begin		//ilhu
			check_one.format = 5;
			check_one.ra_valid = 0;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 9'b010000010;
			check_one.unit = 3;
			check_one.imm = $signed(instr[9:24]);
		end
		else if (instr[0:8] == 9'b011000001) begin		//iohl
			check_one.format = 5;
			check_one.ra_valid = 0;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.op = 9'b011000001;
			check_one.unit = 3;
			check_one.imm = $signed(instr[9:24]);
		end
		else begin
			check_one.format = 4;				//RI10-type
			check_one.ra_valid = 1;
			check_one.rb_valid = 0;
			check_one.rc_valid = 0;
			check_one.imm = $signed(instr[8:17]);
			case(instr[0:7])
				8'b01110100 : begin			//mpyi
					check_one.op = 8'b01110100;
					check_one.unit = 0;
				end
				8'b01110101 : begin			//mpyui
					check_one.op = 8'b01110101;
					check_one.unit = 0;
				end
				8'b00011101 : begin			//ahi
					check_one.op = 8'b00011101;
					check_one.unit = 3;
				end
				8'b00011100 : begin			//ai
					check_one.op = 8'b00011100;
					check_one.unit = 3;
				end
				8'b00001101 : begin			//sfhi
					check_one.op = 8'b00001101;
					check_one.unit = 3;
				end
				8'b00001100 : begin			//sfi
					check_one.op = 8'b00001100;
					check_one.unit = 3;
				end
				8'b00010110 : begin			//andbi
					check_one.op = 8'b00010110;
					check_one.unit = 3;
				end
				8'b00010101 : begin			//andhi
					check_one.op = 8'b00010101;
					check_one.unit = 3;
				end
				8'b00010100 : begin			//andi
					check_one.op = 8'b00010100;
					check_one.unit = 3;
				end
				8'b00000110 : begin			//orbi
					check_one.op = 8'b00000110;
					check_one.unit = 3;
				end
				8'b00000101 : begin			//orhi
					check_one.op = 8'b00000101;
					check_one.unit = 3;
				end
				8'b00000100 : begin			//ori
					check_one.op = 8'b00000100;
					check_one.unit = 3;
				end
				8'b01000110 : begin			//xorbi
					check_one.op = 8'b01000110;
					check_one.unit = 3;
				end
				8'b01000101 : begin			//xorhi
					check_one.op = 8'b01000101;
					check_one.unit = 3;
				end
				8'b01000100 : begin			//xori
					check_one.op = 8'b01000100;
					check_one.unit = 3;
				end
				8'b01111110 : begin			//ceqbi
					check_one.op = 8'b01111110;
					check_one.unit = 3;
				end
				8'b01111101 : begin			//ceqhi
					check_one.op = 8'b01111101;
					check_one.unit = 3;
				end
				8'b01111100 : begin			//ceqi
					check_one.op = 8'b01111100;
					check_one.unit = 3;
				end
				8'b01001110 : begin			//cgtbi
					check_one.op = 8'b01001110;
					check_one.unit = 3;
				end
				8'b01001101 : begin			//cgthi
					check_one.op = 8'b01001101;
					check_one.unit = 3;
				end
				8'b01001100 : begin			//cgti
					check_one.op = 8'b01001100;
					check_one.unit = 3;
				end
				8'b01011110 : begin			//clgtbi
					check_one.op = 8'b01011110;
					check_one.unit = 3;
				end
				8'b01011101 : begin			//clgthi
					check_one.op = 8'b01011101;
					check_one.unit = 3;
				end
				8'b01011100 : begin			//clgti
					check_one.op = 8'b01011100;
					check_one.unit = 3;
				end
				default : check_one.format = 7;
			endcase
			if (check_one.format == 7) begin
				check_one.format = 0;					//RR-type
				check_one.ra_valid = 1;
				check_one.rb_valid = 1;
				check_one.rc_valid = 0;
				case(instr[0:10])
					11'b01111000100 : begin			//mpy
						check_one.op = 11'b01111000100;
						check_one.unit = 0;
					end
					11'b01111001100 : begin			//mpyu
						check_one.op = 11'b01111001100;
						check_one.unit = 0;
					end
					11'b01111000101 : begin			//mpyh
						check_one.op = 11'b01111000101;
						check_one.unit = 0;
					end
					11'b01011000100 : begin			//fa
						check_one.op = 11'b01011000100;
						check_one.unit = 0;
					end
					11'b01011000101 : begin			//fs
						check_one.op = 11'b01011000101;
						check_one.unit = 0;
					end
					11'b01011000110 : begin			//fm
						check_one.op = 11'b01011000110;
						check_one.unit = 0;
					end
					11'b01111000010 : begin			//fceq
						check_one.op = 11'b01111000010;
						check_one.unit = 0;
					end
					11'b01011000010 : begin			//fcgt
						check_one.op = 11'b01011000010;
						check_one.unit = 0;
					end
					11'b00001011111 : begin			//shlh
						check_one.op = 11'b00001011111;
						check_one.unit = 1;
					end
					11'b00001011011 : begin			//shl
						check_one.op = 11'b00001011011;
						check_one.unit = 1;
					end
					11'b00001011100 : begin			//roth
						check_one.op = 11'b00001011100;
						check_one.unit = 1;
					end
					11'b00001011000 : begin			//rot
						check_one.op = 11'b00001011000;
						check_one.unit = 1;
					end
					11'b00001011101 : begin			//rothm
						check_one.op = 11'b00001011101;
						check_one.unit = 1;
					end
					11'b00001011001 : begin			//rotm
						check_one.op = 11'b00001011001;
						check_one.unit = 1;
					end
					11'b00001011110 : begin			//rotmah
						check_one.op = 11'b00001011110;
						check_one.unit = 1;
					end
					11'b00001011010 : begin			//rotma
						check_one.op = 11'b00001011010;
						check_one.unit = 1;
					end
					11'b01010110100 : begin			//cntb
						check_one.op = 11'b01010110100;
						check_one.unit = 2;
						check_one.rb_valid = 0;
					end
					11'b00011010011 : begin			//avgb
						check_one.op = 11'b00011010011;
						check_one.unit = 2;
					end
					11'b00001010011 : begin			//absdb
						check_one.op = 11'b00001010011;
						check_one.unit = 2;
					end
					11'b01001010011 : begin			//sumb
						$display("found  sumb");
						check_one.op = 11'b01001010011;
						check_one.unit = 2;
					end
					11'b00011001000 : begin			//ah
						check_one.op = 11'b00011001000;
						check_one.unit = 3;
					end
					11'b00011000000 : begin			//a
						check_one.op = 11'b00011000000;
						check_one.unit = 3;
					end
					11'b00001001000 : begin			//sfh
						check_one.op = 11'b00001001000;
						check_one.unit = 3;
					end
					11'b00001000000 : begin			//sf
						check_one.op = 11'b00001000000;
						check_one.unit = 3;
					end
					11'b00011000001 : begin			//and
						check_one.op = 11'b00011000001;
						check_one.unit = 3;
					end
					11'b00001000001 : begin			//or
						check_one.op = 11'b00001000001;
						check_one.unit = 3;
					end
					11'b01001000001 : begin			//xor
						check_one.op = 11'b01001000001;
						check_one.unit = 3;
					end
					11'b00011001001 : begin			//nand
						check_one.op = 11'b00011001001;
						check_one.unit = 3;
					end
					11'b01111010000 : begin			//ceqb
						check_one.op = 11'b01111010000;
						check_one.unit = 3;
					end
					11'b01111001000 : begin			//ceqh
						check_one.op = 11'b01111001000;
						check_one.unit = 3;
					end
					11'b01111000000 : begin			//ceq
						check_one.op = 11'b01111000000;
						check_one.unit = 3;
					end
					11'b01001010000 : begin			//cgtb
						check_one.op = 11'b01001010000;
						check_one.unit = 3;
					end
					11'b01001001000 : begin			//cgth
						check_one.op = 11'b01001001000;
						check_one.unit = 3;
					end
					11'b01001000000 : begin			//cgt
						check_one.op = 11'b01001000000;
						check_one.unit = 3;
					end
					11'b01011010000 : begin			//clgtb
						check_one.op = 11'b01011010000;
						check_one.unit = 3;
					end
					11'b01011001000 : begin			//clgth
						check_one.op = 11'b01011001000;
						check_one.unit = 3;
					end
					11'b01011000000 : begin			//clgt
						check_one.op = 11'b01011000000;
						check_one.unit = 3;
					end
					11'b01000000001 : begin			//nop
						check_one.op = 11'b01000000001;
						check_one.unit = 0;
						check_one.reg_write = 0;
					end
					default : check_one.format = 7;
				endcase
				if (check_one.format == 7) begin
					check_one.format = 2;					//RI7-type
					check_one.ra_valid = 1;
					check_one.rb_valid = 0;
					check_one.rc_valid = 0;
					check_one.imm = $signed(instr[11:17]);
					case(instr[0:10])
						11'b00001111011 : begin			//shli
							check_one.op = 11'b00001111011;
							check_one.unit = 1;
						end
						11'b00001111100 : begin			//rothi
							check_one.op = 11'b00001111100;
							check_one.unit = 1;
						end
						11'b00001111000 : begin			//roti
							check_one.op = 11'b00001111000;
							check_one.unit = 1;
						end
						11'b00001111110 : begin			//rotmahi
							check_one.op = 11'b00001111110;
							check_one.unit = 1;
						end
						11'b00001111010 : begin			//rotmai
							check_one.op = 11'b00001111010;
							check_one.unit = 1;
						end
						default begin
							check_one.format = 0;
							check_one.ra_valid = 0;
							check_one.rb_valid = 0;
							check_one.rc_valid = 0;
							check_one.op = 0;
							check_one.unit = 0;
							check_one.rt_addr = 0;
							check_one.imm = 0;
							check_one.even_valid = 0;
						end
					endcase
				end
			end
		end

		if (check_one.even_valid == 0) begin													//odd decoding
			check_one.rt_addr = instr[25:31];
			check_one.ra_addr = instr[18:24];
			check_one.rb_addr = instr[11:17];
			check_one.rc_addr = instr[25:31];
			check_one.reg_write = 1;
			check_one.odd_valid = 1;
			if (instr == 0) begin							//alternate lnop
				check_one.format = 0;
				check_one.ra_valid = 0;
				check_one.rb_valid = 0;
				check_one.rc_valid = 0;
				check_one.op = 0;
				check_one.unit = 0;
				check_one.rt_addr = 0;
				check_one.imm = 0;
				check_one.reg_write = 0;
				check_one.odd_valid = 0;
			end													//RI10-type
			else if (instr[0:7] == 8'b00110100) begin		//lqd
				check_one.format = 4;
				check_one.ra_valid = 1;
				check_one.rb_valid = 0;
				check_one.rc_valid = 0;
				check_one.op = 8'b00110100;
				check_one.unit = 1;
				check_one.imm = $signed(instr[8:17]);
			end
			else if (instr[0:7] == 8'b00100100) begin		//stqd
				check_one.format = 4;
				check_one.ra_valid = 1;
				check_one.rb_valid = 0;
				check_one.rc_valid = 1;
				check_one.op = 8'b00100100;
				check_one.unit = 1;
				check_one.imm = $signed(instr[8:17]);
				check_one.reg_write = 0;
			end
			else begin
				check_one.format = 5;					//RI16-type
				check_one.ra_valid = 0;
				check_one.rb_valid = 0;
				check_one.rc_valid = 0;
				check_one.imm = $signed(instr[9:24]);
				case(instr[0:8])
					9'b001100001 : begin		//lqa
						check_one.op = 9'b001100001;
						check_one.unit = 1;
					end
					9'b001000001 : begin		//stqa
						check_one.op = 9'b001000001;
						check_one.unit = 1;
						check_one.reg_write = 0;
						check_one.rc_valid = 1;
					end
					9'b001100100 : begin		//br
						check_one.op = 9'b001100100;
						check_one.unit = 2;
						check_one.reg_write = 0;
					end
					9'b001100000 : begin		//bra
						check_one.op = 9'b001100000;
						check_one.unit = 2;
						check_one.reg_write = 0;
					end
					9'b001100110 : begin		//brsl
						check_one.op = 9'b001100110;
						check_one.unit = 2;
					end
					9'b001000010 : begin		//brnz
						check_one.op = 9'b001000010;
						check_one.unit = 2;
						check_one.reg_write = 0;
						check_one.rc_valid = 1;
					end
					9'b001000000 : begin		//brz
						check_one.op = 9'b001000000;
						check_one.unit = 2;
						check_one.reg_write = 0;
						check_one.rc_valid = 1;
					end
					default : check_one.format = 7;
				endcase
				if (check_one.format == 7) begin
					check_one.format = 0;					//RR-type
					check_one.ra_valid = 1;
					check_one.rb_valid = 1;
					check_one.rc_valid = 0;
					//$display("check: instr[0:10] %b ",instr[0:10]);
					case(instr[0:10])
						11'b00111011011 : begin		//shlqbi
							$display("shlqbi ");
							check_one.op = 11'b00111011011;
							check_one.unit = 0;
						end
						11'b00111011111 : begin		//shlqby
							check_one.op = 11'b00111011111;
							check_one.unit = 0;
						end
						11'b00111011000 : begin		//rotqbi
							check_one.op = 11'b00111011000;
							check_one.unit = 0;
						end
						11'b00111011100 : begin		//rotqby
							check_one.op = 11'b00111011100;
							check_one.unit = 0;
						end
						11'b00110110010 : begin		//gbb
							check_one.op = 11'b00110110010;
							check_one.unit = 0;
							check_one.rb_valid = 0;
						end
						11'b00110110001 : begin		//gbh
							check_one.op = 11'b00110110001;
							check_one.unit = 0;
							check_one.rb_valid = 0;
						end
						11'b00110110000 : begin		//gb
							check_one.op = 11'b00110110000;
							check_one.unit = 0;
							check_one.rb_valid = 0;
						end
						11'b00111000100 : begin		//lqx
							check_one.op = 11'b00111000100;
							check_one.unit = 1;
						end
						11'b00101000100 : begin		//stqx
							check_one.op = 11'b00101000100;
							check_one.unit = 1;
							check_one.reg_write = 0;
							check_one.rc_valid = 1;
						end
						11'b00110101000 : begin		//bi
							check_one.op = 11'b00110101000;
							check_one.unit = 2;
							check_one.reg_write = 0;
							check_one.rb_valid = 0;
						end
						11'b00000000001 : begin		//lnop
							check_one.op = 11'b00000000001;
							check_one.unit = 0;
							check_one.reg_write = 0;
						end
						default : check_one.format = 7;
					endcase
					if (check_one.format == 7) begin
						check_one.format = 2;					//RI7-type
						check_one.ra_valid = 1;
						check_one.rb_valid = 0;
						check_one.rc_valid = 0;
						check_one.imm = $signed(instr[11:17]);
						case(instr[0:10])
							11'b00111111011 : begin		//shlqbii
								check_one.op = 11'b00111111011;
								check_one.unit = 0;
							end
							11'b00111111111 : begin		//shlqbyi
								check_one.op = 11'b00111111111;
								check_one.unit = 0;
							end
							11'b00111111000 : begin		//rotqbii
								check_one.op = 11'b00111111000;
								check_one.unit = 0;
							end
							11'b00111111100 : begin		//rotqbyi
								check_one.op = 11'b00111111100;
								check_one.unit = 0;
							end
							default begin
								check_one.format = 0;
								check_one.ra_valid = 0;
								check_one.rb_valid = 0;
								check_one.rc_valid = 0;
								check_one.op = 0;
								check_one.unit = 0;
								check_one.rt_addr = 0;
								check_one.imm = 0;
								check_one.odd_valid = 0;
							end
						endcase
					end
				end
			end
		end
		else check_one.odd_valid = 0;		
	endfunction

endmodule