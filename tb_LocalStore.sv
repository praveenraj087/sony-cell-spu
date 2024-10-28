module tb_LocalStore();
	logic			clk, reset;
	
	//RF/FWD Stage
	logic [0:10]	op;				//Decoded opcode, truncated based on format
	logic [2:0]		format;			//Format of instr, used with op and imm
	logic [0:6]		rt_addr;		//Destination register address
	logic [0:127]	ra, rb, rt_st_odd;	//Values of source registers
	logic [0:17]	imm;			//Immediate value, truncated based on format
	logic			reg_write;		//Will current instr write to RegTable
	
	//WB Stage
	logic [0:127]	rt_wb;			//Output value of Stage 3
	logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	logic			reg_write_wb;	//Will rt_wb write to RegTable
	
	LocalStore dut(clk, reset, op, format, rt_addr, ra, rb, rt_st_odd, imm, reg_write, rt_wb,
		rt_addr_wb, reg_write_wb);
		
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
		//for (int i=0; i<8; i++)
		//	rb[i*16 +:16] = rb[i*16 +:16] + 1;
	end
		
	initial begin
		reset = 1;
		format = 3'b000;
		op = 11'b00101000100;						//stqx
		rt_addr = 7'b0000011;						//RT = $r3
		ra = 128'h00000010000100010001000100010001;	//Halfwords: 16'h0001
		rb = 128'h000000F0000100010001000100010001;	//Halfwords: 16'h0001
		rt_st_odd = 128'h00000001000100010001000100010001;
		imm = 12;
		reg_write = 1;
		
		#6;
		reset = 0;									//@11ns, enable unit
		
		@(posedge clk); #1;
		op = 11'b00111000100;						//lqx
		@(posedge clk); #1;
		op = 8'b00100100;							//stqd
		format = 4;
		rt_st_odd = 128'h00000002000200020002000200020002;
		@(posedge clk); #1;
		op = 8'b00110100;							//lqd
		@(posedge clk); #1;
		op = 9'b001000001;							//stqa
		format = 5;
		rt_st_odd = 128'h00000003000300030003000300030003;
		@(posedge clk); #1;
		op = 9'b001100001;							//lqa
		@(posedge clk); #1;
		op = 0;										//nop
		#100; $stop; // Stop simulation
	end
endmodule