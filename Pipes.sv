module Pipes(clk, reset, instr_even, instr_odd, pc, pc_wb, branch_taken, op_even, op_odd, unit_even, unit_odd, rt_addr_even, rt_addr_odd, format_even, format_odd,
	imm_even, imm_odd, reg_write_even, reg_write_odd, first_odd, rt_addr_delay_even, reg_write_delay_even, rt_addr_delay_odd, reg_write_delay_odd,
	rt_addr_delay_fp1, reg_write_delay_fp1, int_delay_fp1, rt_addr_delay_fx2, reg_write_delay_fx2, rt_addr_delay_b1, reg_write_delay_b1, rt_addr_delay_fx1, reg_write_delay_fx1,
	rt_addr_delay_p1, reg_write_delay_p1, rt_addr_delay_ls1, reg_write_delay_ls1);
	input logic clk, reset;
	input logic[0:31]	instr_even, instr_odd;				//Instr from decoder
	input logic [7:0]	pc;									//Program counter from IF stage

	//Nets from decode logic
	input logic [2:0]	format_even, format_odd;			//Format of instr
	input logic [0:10]	op_even, op_odd;					//Opcode of instr (used with format)
	input logic [1:0]	unit_even, unit_odd;				//Destination unit of instr; Order of: FP, FX2, Byte, FX1 (Even); Perm, LS, Br (Odd)
	input logic [0:6]	rt_addr_even, rt_addr_odd;			//Destination register addresses
	logic [0:127]		ra_even, rb_even, rc_even, ra_odd, rb_odd, rt_st_odd;	//Register values from RegTable
	input logic [0:17]	imm_even, imm_odd;					//Full possible immediate value (used with format)
	input logic			reg_write_even, reg_write_odd;		//1 if instr will write to rt, else 0
	input				first_odd;							//1 if odd instr is first in pair, 0 else; Used for branch flushing

	//Signals for writing back to RegTable
	logic [0:127]	rt_even_wb, rt_odd_wb;					//Values to be written back to RegTable
	logic [0:6]		rt_addr_even_wb, rt_addr_odd_wb;		//Destination register addresses
	logic			reg_write_even_wb, reg_write_odd_wb;	//1 if instr will write to rt, else 0

	//Signals for forwarding logic
	logic [6:0][0:127]	fw_even_wb, fw_odd_wb;				//Pipe shift registers of values ready to be forwarded
	logic [6:0][0:6]	fw_addr_even_wb, fw_addr_odd_wb;	//Destinations of values to be forwarded
	logic [6:0]			fw_write_even_wb, fw_write_odd_wb;	//Will forwarded values be writted to reg?
	logic [0:127]		ra_even_fwd, rb_even_fwd, rc_even_fwd, ra_odd_fwd, rb_odd_fwd, rt_st_odd_fwd;	//Updated input values

	//Signals for handling branches
	output logic [7:0]	pc_wb;								//New program counter for branch
	output logic		branch_taken;						//Was branch taken?
	logic				branch_kill;						//If branch is taken and branch instr is first in pair, kill twin instr
	logic [2:0]			format_even_live;					//Format of instr, only valid if branch not taken by first instr
	logic [0:10]		op_even_live;						//Opcode of instr, only valid if branch not taken by first instr
	
	//Internal Signals for Handling RAW Hazards
	output logic [0:6]	rt_addr_delay_even, rt_addr_delay_odd;			//Destination register for rt_wb
	output logic		reg_write_delay_even, reg_write_delay_odd;		//Will rt_wb write to RegTable
	
	output logic [6:0][0:6]	rt_addr_delay_fp1;		//Destination register for rt_wb
	output logic [6:0]		reg_write_delay_fp1;	//Will rt_wb write to RegTable
	output logic [6:0]		int_delay_fp1;			//Will fp1 write an int result
	
	output logic [3:0][0:6]	rt_addr_delay_fx2;		//Destination register for rt_wb
	output logic [3:0]		reg_write_delay_fx2;	//Will rt_wb write to RegTable
	
	output logic [3:0][0:6]	rt_addr_delay_b1;		//Destination register for rt_wb
	output logic [3:0]		reg_write_delay_b1;		//Will rt_wb write to RegTable
	
	output logic [1:0][0:6]	rt_addr_delay_fx1;		//Destination register for rt_wb
	output logic [1:0]		reg_write_delay_fx1;	//Will rt_wb write to RegTable
	
	output logic [3:0][0:6]	rt_addr_delay_p1;		//Destination register for rt_wb
	output logic [3:0]		reg_write_delay_p1;		//Will rt_wb write to RegTable
	
	output logic [5:0][0:6]	rt_addr_delay_ls1;		//Destination register for rt_wb
	output logic [5:0]		reg_write_delay_ls1;	//Will rt_wb write to RegTable

	RegisterTable rf(.clk(clk), .reset(reset), .instr_even(instr_even), .instr_odd(instr_odd),
		.ra_even(ra_even), .rb_even(rb_even), .rc_even(rc_even), .ra_odd(ra_odd), .rb_odd(rb_odd), .rt_st_odd(rt_st_odd), .rt_addr_even(rt_addr_even_wb),
		.rt_addr_odd(rt_addr_odd_wb), .rt_even(rt_even_wb), .rt_odd(rt_odd_wb), .reg_write_even(reg_write_even_wb), .reg_write_odd(reg_write_odd_wb));

	EvenPipe ev(.clk(clk), .reset(reset), .op(op_even_live), .format(format_even_live), .unit(unit_even), .rt_addr(rt_addr_even), .ra(ra_even_fwd), .rb(rb_even_fwd), .rc(rc_even_fwd),
		.imm(imm_even), .reg_write(reg_write_even), .rt_wb(rt_even_wb), .rt_addr_wb(rt_addr_even_wb), .reg_write_wb(reg_write_even_wb), .branch_taken(branch_taken),
		.fw_wb(fw_even_wb), .fw_addr_wb(fw_addr_even_wb), .fw_write_wb(fw_write_even_wb),
		.rt_addr_delay_fp1(rt_addr_delay_fp1), .reg_write_delay_fp1(reg_write_delay_fp1), .int_delay_fp1(int_delay_fp1),
		.rt_addr_delay_fx2(rt_addr_delay_fx2), .reg_write_delay_fx2(reg_write_delay_fx2), .rt_addr_delay_b1(rt_addr_delay_b1),
		.reg_write_delay_b1(reg_write_delay_b1), .rt_addr_delay_fx1(rt_addr_delay_fx1), .reg_write_delay_fx1(reg_write_delay_fx1));

	OddPipe od(.clk(clk), .reset(reset), .op(op_odd), .format(format_odd), .unit(unit_odd), .rt_addr(rt_addr_odd), .ra(ra_odd_fwd), .rb(rb_odd_fwd),
		.rt_st(rt_st_odd_fwd), .imm(imm_odd), .reg_write(reg_write_odd), .pc_in(pc), .rt_wb(rt_odd_wb), .rt_addr_wb(rt_addr_odd_wb), .reg_write_wb(reg_write_odd_wb),
		.pc_wb(pc_wb), .branch_taken(branch_taken), .fw_wb(fw_odd_wb), .fw_addr_wb(fw_addr_odd_wb), .fw_write_wb(fw_write_odd_wb), .first(first_odd), .branch_kill(branch_kill),
		.rt_addr_delay_p1(rt_addr_delay_p1), .reg_write_delay_p1(reg_write_delay_p1), 
		.rt_addr_delay_ls1(rt_addr_delay_ls1), .reg_write_delay_ls1(reg_write_delay_ls1));

	Forward fwd(.clk(clk), .reset(reset), .instr_even(instr_even), .instr_odd(instr_odd), .ra_even(ra_even), .rb_even(rb_even), .rc_even(rc_even),
		.ra_odd(ra_odd), .rb_odd(rb_odd), .rt_st_odd(rt_st_odd), .ra_even_fwd(ra_even_fwd), .rb_even_fwd(rb_even_fwd), .rc_even_fwd(rc_even_fwd),
		.ra_odd_fwd(ra_odd_fwd), .rb_odd_fwd(rb_odd_fwd), .rt_st_odd_fwd(rt_st_odd_fwd), .fw_even_wb(fw_even_wb), .fw_addr_even_wb(fw_addr_even_wb),
		.fw_write_even_wb(fw_write_even_wb), .fw_odd_wb(fw_odd_wb), .fw_addr_odd_wb(fw_addr_odd_wb), .fw_write_odd_wb(fw_write_odd_wb));
		
	
	always_comb begin
		if (branch_kill == 0) begin			//If branch is taken and branch is first instr in pair, kill corresponding even instr
			format_even_live = format_even;
			op_even_live = op_even;
		end
		else begin
			format_even_live = 0;
			op_even_live = 0;
		end
		
		rt_addr_delay_even = rt_addr_even;
		reg_write_delay_even = reg_write_even;
		rt_addr_delay_odd = rt_addr_odd;
		reg_write_delay_odd = reg_write_odd;
	end
	
endmodule