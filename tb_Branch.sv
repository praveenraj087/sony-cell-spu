module tb_Branch();
	logic			clk, reset;
	
	//RF/FWD Stage
	logic [0:10]	op;				//Decoded opcode, truncated based on format
	logic [2:0]		format;			//Format of instr, used with op and imm
	logic [0:6]		rt_addr;		//Destination register address
	logic [0:127]	ra, rb, rt_st;	//Values of source registers
	logic [0:17]	imm;			//Immediate value, truncated based on format
	logic			reg_write;		//Will current instr write to RegTable
	logic [7:0]		pc_in;			//Program counter from IF stage
	
	//WB Stage
	logic [0:127]	rt_wb;			//Output value of Stage 3
	logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	logic			reg_write_wb;	//Will rt_wb write to RegTable
	logic [7:0]		pc_wb;			//New program counter for branch
	logic			branch_taken;	//Was branch taken?
	
	Branch dut(clk, reset, op, format, rt_addr, ra, rb, rt_st, imm, reg_write, pc_in, rt_wb,
		rt_addr_wb, reg_write_wb, pc_wb, branch_taken);
		
	// Initialize the clock to zero.
	initial
		clk = 0;

	// Make the clock oscillate: every 5 time units, it changes its value.
	always begin
		#5 clk = ~clk;
		pc_in = pc_in + 1;
		$display("%d: reset = %h, format = %h, op = %h, rt_addr = %h, ra = %h,
			rb = %h, imm = %h, reg_write = %h, rt_wb = %h, rt_addr_wb = %h,
			reg_write_wb = %h", $time, reset, format, op, rt_addr, ra, rb, imm, reg_write,
			rt_wb, rt_addr_wb, reg_write_wb);
	end
		
	initial begin
		reset = 1;
		format = 3'b000;
		op = 11'b00110101000;						//bi
		rt_addr = 7'b0000011;						//RT = $r3
		ra = 128'h00000025000100010001000100010001;
		rb = 128'h00010001000100010001000100010001;	//Halfwords: 16'h0001
		rt_st = 128'h00010001000100010001000100010001;
		imm = 12;
		reg_write = 1;
		pc_in = 0;
		
		#6;
		reset = 0;									//@11ns, enable unit
		
		@(posedge clk); #1;
		op = 9'b001100110;							//brsl
		format = 5;
		@(posedge clk); #1;
		op = 9'b001100100;							//br
		@(posedge clk); #1;
		op = 9'b001100000;							//bra
		@(posedge clk); #1;
		op = 9'b001000010;							//brnz
		@(posedge clk); #1;
		op = 9'b001000000;							//brz
		@(posedge clk); #1;
		op = 9'b001000010;							//brnz
		rt_st = 0;
		@(posedge clk); #1;
		op = 9'b001000000;							//brz
		@(posedge clk); #1;
		op = 0;										//nop
		#100; $stop; // Stop simulation
	end
endmodule