module tb_Byte();
	logic			clk, reset;
	
	//RF/FWD Stage
	logic [0:10]	op;				//Decoded opcode, truncated based on format
	logic [2:0]		format;			//Format of instr, used with op and imm
	logic [0:6]		rt_addr;		//Destination register address
	logic [0:127]	ra, rb;			//Values of source registers
	logic [0:17]	imm;			//Immediate value, truncated based on format
	logic			reg_write;		//Will current instr write to RegTable
	
	//WB Stage
	logic [0:127]	rt_wb;			//Output value of Stage 3
	logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	logic			reg_write_wb;	//Will rt_wb write to RegTable
	
	Byte dut(clk, reset, op, format, rt_addr, ra, rb, imm, reg_write, rt_wb, rt_addr_wb,
		reg_write_wb);
		
	// Initialize the clock to zero.
	initial
		clk = 0;

	// Make the clock oscillate: every 5 time units, it changes its value.
	always begin
		#5 clk = ~clk;
		$display("%d: reset = %h, format = %h, op = %h, rt_addr = %h, ra = %h,
			rb = %h, imm = %h, reg_write = %h, rt_wb = %h, rt_addr_wb = %h,
			reg_write_wb = %h", $time, reset, format, op, rt_addr, ra, rb, imm, reg_write,
			rt_wb, rt_addr_wb, reg_write_wb);
	end
		
	initial begin
		reset = 1;
		format = 3'b000;
		op = 11'b01010110100;						//cntb
		rt_addr = 7'b0000011;						//RT = $r3
		ra = 128'h0003000F000100010001000100010001;	//Halfwords: 16'h0010
		rb = 128'h00FB0000000100010001000100010001;	//Halfwords: 16'h0001
		imm = 0;
		reg_write = 1;
		
		#6;
		reset = 0;									//@11ns, enable unit
		
		@(posedge clk); #1;
		op = 11'b00011010011;						//avgb
		@(posedge clk); #1;
		op = 11'b00001010011;						//absdb
		@(posedge clk); #1;
		op = 11'b01001010011;						//sumb
		@(posedge clk); #1;
		op = 0;										//nop
		#100; $stop; // Stop simulation
	end
endmodule