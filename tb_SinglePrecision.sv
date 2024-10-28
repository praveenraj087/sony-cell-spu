module tb_SinglePrecision();
	logic			clk, reset;
	
	//RF/FWD Stage
	logic [0:10]	op;				//Decoded opcode, truncated based on format
	logic [2:0]		format;			//Format of instr, used with op and imm
	logic [0:6]		rt_addr;		//Destination register address
	logic [0:127]	ra, rb, rc;		//Values of source registers
	logic [0:17]	imm;			//Immediate value, truncated based on format
	logic			reg_write;		//Will current instr write to RegTable
	
	//WB Stage
	logic [0:127]	rt_wb;			//Output value of Stage 6
	logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	logic			reg_write_wb;	//Will rt_wb write to RegTable
	
	logic [0:127]	rt_int;			//Output value of Stage 7
	logic [0:6]		rt_addr_int;	//Destination register for rt_wb
	logic			reg_write_int;	//Will rt_wb write to RegTable
	
	SinglePrecision dut(clk, reset, op, format, rt_addr, ra, rb, rc, imm, reg_write, rt_wb,
		rt_addr_wb, reg_write_wb, rt_int, rt_addr_int, reg_write_int);
		
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
		op = 11'b01111000100;						//mpy
		rt_addr = 7'b0000011;						//RT = $r3
		ra = 128'h00007FFFFFFFFFFF000A0009FFFFFFF5;	//Halfwords: 16'h0010
		rb = 128'h00008000000100030004000500060008;	//Halfwords: 16'h0001
		rc = 128'h000000020001000200040002FFF60002;
		imm = 42;
		reg_write = 1;
		
		#6;
		reset = 0;									//@11ns, enable unit
		
		@(posedge clk); #1;
		op = 11'b01111001100;						//mpyu
		@(posedge clk); #1;
		op = 11'b01111000101;						//mpyh
		@(posedge clk); #1;
		format = 1;
		op = 4'b1100;								//mpya
		@(posedge clk); #1;
		format = 4;
		op = 8'b01110100;							//mpyi
		@(posedge clk); #1;
		op = 8'b01110101;							//mpyui
		@(posedge clk); #1;
		op = 0;										//nop
		@(posedge clk);
		@(posedge clk);
		@(posedge clk); #1;
		format = 3'b000;
		op = 11'b01011000100;						//fa
		rt_addr = 7'b0000011;						//RT = $r3
		ra = 128'h4228000040647ae1bfc00000bb83126f;	//42, ~3.57, -1.5, ~-0.004
		rb = 128'h42480000000000003e4ccccdbb83126f;	//50, 0, ~0.2, ~-0.004
		rc = 128'hc12000003dcccccd49742400bd800000; //-10, ~0.1, 1000000, -0.625
		imm = 173;
		@(posedge clk); #1;
		op = 11'b01011000101;						//fs
		@(posedge clk); #1;
		op = 11'b01011000110;						//fm
		@(posedge clk); #1;
		op = 11'b01111000010;						//fceq
		@(posedge clk); #1;
		op = 11'b01011000010;						//fcgt
		@(posedge clk); #1;
		format = 1;
		op = 4'b1110;								//fma
		@(posedge clk); #1;
		op = 4'b1111;								//fms
		@(posedge clk); #1;
		format = 3;
		op = 10'b0111011000;						//cflts
		@(posedge clk); #1;
		op = 10'b0111011001;						//cfltu
		@(posedge clk); #1;
		op = 0;
		
		
		
		#200; $stop; // Stop simulation
	end
endmodule