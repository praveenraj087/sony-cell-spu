module Branch(clk, reset, op, format, rt_addr, ra, rb, rt_st, imm, reg_write, pc_in, rt_wb, rt_addr_wb, reg_write_wb, pc_wb, branch_taken, first, branch_kill);
	input			clk, reset;
	
	//RF/FWD Stage
	input [0:10]	op;				//Decoded opcode, truncated based on format
	input [2:0]		format;			//Format of instr, used with op and imm
	input [0:6]		rt_addr;		//Destination register address
	input [0:127]	ra, rb, rt_st;			//Values of source registers
	input [0:17]	imm;			//Immediate value, truncated based on format
	input			reg_write;		//Will current instr write to RegTable
	input [7:0]		pc_in;			//Program counter from IF stage
	input			first;			//1 if first instr in pair; used for determining order of branch
	
	//WB Stage
	output logic [0:127]	rt_wb;			//Output value of Stage 3
	output logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	output logic			reg_write_wb;	//Will rt_wb write to RegTable
	output logic [7:0]		pc_wb;			//New program counter for branch
	output logic			branch_taken;	//Was branch taken?
	output logic			branch_kill;		//If branch is taken and branch instr is first in pair, kill twin instr
	
	//Internal Signals
	logic [0:127]	rt_delay;			//Staging register for calculated values
	logic [0:6]		rt_addr_delay;		//Destination register for rt_wb
	logic			reg_write_delay;	//Will rt_wb write to RegTable
	logic [7:0]		pc_delay;			//Staging register for PC
	logic			branch_delay;		//Was branch taken?
	
	always_ff @(posedge clk) begin
		if (reset == 1) begin
			rt_wb <= 0;
			rt_addr_wb <= 0;
			reg_write_wb <= 0;
			pc_wb <= 0;
			branch_taken <= 0;
		end
		else begin
			rt_wb <= rt_delay;
			rt_addr_wb <= rt_addr_delay;
			reg_write_wb <= reg_write_delay;
			pc_wb <= pc_delay;
			branch_taken <= branch_delay;
		end
	end
	
	always_comb begin
		if (format == 0 && op == 0) begin					//nop : No Operation (Load)
			rt_delay = 0;
			rt_addr_delay = 0;
			reg_write_delay = 0;
			pc_delay = 0;
			branch_delay = 0;
		end
		else begin
			rt_addr_delay = rt_addr;
			reg_write_delay = reg_write;
			if (branch_taken) begin
				rt_delay = 0;
				rt_addr_delay = 0;
				reg_write_delay = 0;
				pc_delay = 0;
				branch_delay = 0;
			end
			else if (format == 0) begin
				case (op)
					11'b00110101000 : begin				//bi : Branch Indirect
						pc_delay = ra[0:31];
						reg_write_delay = 0;
						branch_delay = 1;
					end
					default begin
						rt_delay = 0;
						rt_addr_delay = 0;
						reg_write_delay = 0;
						pc_delay = 0;
						branch_delay = 0;
					end
				endcase
			end
			else if (format == 5) begin
				case (op[2:10])
					9'b001100110 : begin				//brsl: Branch Relative and Set Link
						rt_delay[0:31] = pc_in + 1;
						rt_delay[32:127] = 0;
						pc_delay = imm[2:17] + pc_in;
						branch_delay = 1;
					end
					9'b001100100 : begin				//br: Branch Relative
						pc_delay = imm[2:17] + pc_in;
						branch_delay = 1;
					end
					9'b001100000 : begin				//bra: Branch Absolute
						pc_delay = imm[2:17];
						branch_delay = 1;
					end
					9'b001000010 : begin				//brnz: Branch If Not Zero Word
						if (first)
							pc_delay = pc_in - 2 + $signed(imm[2:17]);
						else
							pc_delay = pc_in - 1 + $signed(imm[2:17]);
						branch_delay = (rt_st[0:31] == 32'h0000) ? 0 : 1;
					end
					9'b001000000 : begin				//brz: Branch If Zero Word
						if (first)
							pc_delay = pc_in - 2 + $signed(imm[2:17]);
						else
							pc_delay = pc_in - 1 + $signed(imm[2:17]);
						branch_delay = (rt_st[0:31] == 32'h0000) ? 1 : 0;
					end
					default begin
						rt_delay = 0;
						rt_addr_delay = 0;
						reg_write_delay = 0;
						pc_delay = 0;
						branch_delay = 0;
					end
				endcase
			end
			else begin
				rt_delay = 0;
				rt_addr_delay = 0;
				reg_write_delay = 0;
				pc_delay = 0;
				branch_delay = 0;
			end
		end
		
		if (branch_delay == 1 && first == 1)
			branch_kill = 1;
		else
			branch_kill = 0;
	end
endmodule