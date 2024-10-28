module tb_Pipes();
	logic			clk, reset;
	logic [0:31]	instr_even, instr_odd;					//Instr from decoder
	logic [7:0]		pc;										//Program counter from IF stage
	
	//Signals for handling branches
	logic [7:0]		pc_wb;									//New program counter for branch
	logic			branch_taken;							//Was branch taken?
	
	Pipes dut(clk, reset, instr_even, instr_odd, pc, pc_wb, branch_taken);
		
	// Initialize the clock to zero.
	initial
		clk = 0;

	// Make the clock oscillate: every 5 time units, it changes its value.
	always begin
		#5 clk = ~clk;
		/*$display("%d: reset = %h, format = %h, op = %h, rt_addr = %h, ra = %h,
			rb = %h, imm = %h, reg_write = %h, rt_wb = %h, rt_addr_wb = %h,
			reg_write_wb = %h", $time, reset, format, op, rt_addr, ra, rb, imm, reg_write,
			rt_wb, rt_addr_wb, reg_write_wb);*/
		pc = pc + 1;
	end
		
	initial begin
		reset = 1;
		pc = 0;
		instr_even = 0;
		instr_odd = 0;
		
		
		#6;
		reset = 0;											//@11ns, enable unit
		
		@(posedge clk); //#1;								//@15ns
		instr_even = 32'b01000001100011111000011110000001;	//ilh $1, 0x1F0F
		instr_odd = 32'b0;									//lnop
		
		@(posedge clk); //#1;								//@15ns
		instr_even = 32'b01000001101010010111100000000010;	//ilh $2, 0x52F0
		instr_odd = 32'b0;									//lnop
		
		@(posedge clk); //#1;
		instr_even = 0; instr_odd = 0;
		@(posedge clk);
		
		@(posedge clk); //#1;								//@20ns
		instr_even = 32'b00011001000000001000000010000011;	//ah $3, $1, $2
		instr_odd = 32'b0;									//nop (ls)
		
		@(posedge clk); //#1; 
		instr_even = 0; instr_odd = 0;
		@(posedge clk);
		
		@(posedge clk); //#1;								//@25ns
		instr_even = 32'b01000001100000000000000110000100;	//ilh $4, 0x0003
		instr_odd = 32'b0;									//nop (ls)
		
		@(posedge clk); //#1; 
		instr_even = 0; instr_odd = 0;
		@(posedge clk);
		
		@(posedge clk); //#1; 								//@30ns
		instr_even = 32'b00001101000000000000001000000110;	//sfhi $6, 0 (!$4 + 1)
		instr_odd = 0;	
		
		@(posedge clk); //#1; 
		instr_even = 0; instr_odd = 0;
		@(posedge clk);
		
		@(posedge clk); #1;									//@35ns
		instr_even = 32'b00001011101000011000000110000101;	//rothm $5, $3, $6
		instr_odd = 32'b00111011100000010000000110000111;	//rotqby $7, $3, $4
		
		@(posedge clk); //#1; 
		instr_even = 0; instr_odd = 0;
		@(posedge clk);
		
		@(posedge clk); #1;									//@35ns
		instr_even = 32'b00001011110000011000000110000101;	//rotmah $5, $3, $6
		instr_odd = 0;
		
		@(posedge clk); #1;									//@40ns
		instr_even = 0; instr_odd = 0;
		
		@(posedge clk); #1;									//@45ns
		
		@(posedge clk); #1;									//@50ns
		#200; $stop;
	end
endmodule