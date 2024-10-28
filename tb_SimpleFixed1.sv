module tb_SimpleFixed1();
	logic			clk, reset;

	//RF/FWD Stage
	logic [0:10]	op;				//Decoded opcode, truncated based on format
	logic [2:0]		format;			//Format of instr, used with op and imm
	logic [0:6]		rt_addr;		//Destination register address
	logic [0:127]	ra, rb,rt_st;			//Values of source registers
	logic [0:17]	imm;			//Immediate value, truncated based on format
	logic			reg_write;		//Will current instr write to RegTable

	//WB Stage
	logic [0:127]	rt_wb;			//Output value of Stage 3
	logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	logic			reg_write_wb;	//Will rt_wb write to RegTable

	SimpleFixed1 dut(clk, reset, op, format, rt_addr, ra, rb, rt_st, imm, reg_write, rt_wb,
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
	end

	initial begin
		reset = 1;
		format = 3'b000;
		op = 11'b01010110100;						//shlh
		rt_addr = 7'b0000011;						//RT = $r3
		ra = 128'h00010001000100010001000100010001;	//Halfwords: 16'h0010
		rb = 128'h00010001000100010001000100010001;	//Halfwords: 16'h0001
		imm = 0;
		reg_write = 1;

		#6;
		reset = 0;									//@11ns, enable unit

		@(posedge clk); #1;
		op = 0;										//@16ns, instr = nop

		@(posedge clk);
		// Add Halfword
		#1; op = 11'b00011001000;
		ra = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE;
		@(posedge clk);
		//#1; op = 0;
		// @(posedge clk);
		// #1; op = 11'b00001011111;
		// @(posedge clk);
		//#1; op = 0;
		@(posedge clk);
		#1; op = 11'b00011001000;
		// Add Halfword
		ra = 128'h80005678800000007FFFFFFF7FFF7FFF;
		rb = 128'h80001234800000000000000180008000;
		@(posedge clk);
		#1; op = 11'b00011001000;
		// Add Halfword
		ra = 128'h80005678800000007FFFFFFF7FFF7FFF;
		rb = 128'h80001234800000000000000180008000;
		@(posedge clk);
		#1;
		ra = 128'h00101131337377F7FF00000000000FF;

		@(posedge clk);
		//sfh rt, ra, rb : Subtract from Halfword
		#1; op = 11'b00001001000;
			ra = 128'h7FFF9FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			rb = 128'h80001234800000000000000180008000;


		@(posedge clk);
		//sfh rt, ra, rb : Subtract from Halfword
		#1; op = 11'b00001001000;
			ra = 128'hF7777FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			rb = 128'h01001234800000000000000180008000;

		@(posedge clk);
		//sf rt, ra, rb : Subtract from Word
		#1; op = 11'b00001000000;
			ra = 128'h7FFF9FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			rb = 128'h80001234800000000000000180008000;


		@(posedge clk);
		//sf rt, ra, rb : Subtract from Word
		#1; op = 11'b00001000000;
			ra = 128'hF7777FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			rb = 128'h01001234800000000000000180008000;

		@(posedge clk);
		//sfhi rt, ra, imm10 : Subtract from Halfword Immediate
		#1; op = 8'b00001101;
			format = 4;
			ra = 128'h7FFF9FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			imm = 10'b0011111111;


		@(posedge clk);
		//sfhi rt, ra, imm10 : Subtract from Halfword Immediate
		#1; op =8'b00001101;
			format = 4;
			ra = 128'hF7777FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			imm = 10'b1011111111;

		@(posedge clk);
		//sfi rt, ra, imm10 : Subtract from Word Immediate
		#1; op = 8'b00001101;
			format = 4;
			ra = 128'h7FFF9FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			imm = 10'b0011111111;


		@(posedge clk);
		//sfi rt, ra, imm10 : Subtract from Word Immediate
		#1; op = 11'b00001000000;
			ra = 128'hF7777FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			imm = 10'b1011111111;
			format = 4;


		@(posedge clk);
		//Add Word
		#1; op = 11'b00011000000;
		format = 0;
		ra = 128'h80000000800000007FFFFFFF7FFFFFFF;	rb = 128'h80000000800000000000000180000000;
		@(posedge clk);
		//Add Word
		#1; op = 11'b00011000000;
		ra = 128'h90000000900000009000000090000000;	rb = 128'h10001000100010001000100010001000;


		@(posedge clk);
		//ahi rt, ra, imm10 : Add Halfword Immediate
		#1; op = 8'b00011101;
		format = 4;
		ra = 128'h80000000800000007FFFFFFF7FFFFFFF;	imm = 10'b0011111111;
		@(posedge clk);
		//ai rt, ra, imm10 : Add Word Immediate
		#1; op = 8'b00011100;
		format = 4;
		ra = 128'h90000000900000009000000090000000;	imm = 10'b1011111111;


		@(posedge clk);
		format = 3'b000;
		#1; op=11'b00011000001;
		ra = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		rb = 128'h10001000100010001000100010001000;
		@(posedge clk);
		#1; op = 11'b00001000001;
			ra = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			rb = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
		@(posedge clk);
		#1; op = 11'b01001000001;
		@(posedge clk);
		#1; op = 11'b00011001001;
		@(posedge clk);
		#1; op = 11'b01111010000;
		@(posedge clk);
		#1; op = 11'b01111010000;
			ra = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			rb = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		// ceqb rt, ra, rb Compare Equal Byte
		#1; op = 11'b01111001000;
		@(posedge clk);
		// ceqh rt, ra, rb Compare Equal Halfword
		#1; op = 11'b01111001000;
			ra = 128'h7F007F007F007FFF7FFF7FFF7FFF7F00;
			rb = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		// ceqb rt, ra, rb Compare Equal Byte
		#1; op = 11'b01111000000;
		@(posedge clk);
		// ceq rt, ra, rb Compare Equal Word
		#1; op = 11'b01111000000;
			ra = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
			rb = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;

		@(posedge clk);
		// cgtb rt, ra, rb Compare Greater Than Byte
		#1; op = 11'b01001010000;
		@(posedge clk);
		// cgtb rt, ra, rb Compare Greater Than Byte
		#1; op = 11'b01001010000;
			ra = 128'h7FFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			rb = 128'h76FF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		// cgth rt, ra, rb Compare Greater Than Halfword
		#1; op = 11'b01001001000;
			ra = 128'h7FFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			rb = 128'h77FF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		// cgt rt, ra, rb Compare Greater Than Word
		#1; op = 11'b01001000000;
			ra = 128'h7FFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			rb = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		// clgtb rt, ra, rb Compare Logical Greater Than Byte
		#1; op = 11'b01011010000;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			rb = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		// clgth rt, ra, rb Compare Logical Greater Than Halfword
		#1; op = 11'b01011001000;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			rb = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		// clgt rt, ra, rb Compare Logical Greater Than Word
		#1; op = 11'b01011000000;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			rb = 128'h7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF;
		@(posedge clk);
		 // andbi rt, ra, imm10 And Byte Immediate
		#1; op = 8'b00010110;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b0000000111;
		@(posedge clk);
		// andhi rt, ra, imm10 And Halfword Immediate
		#1; op = 8'b00010101;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b0000000111;
		@(posedge clk);
		// andhi rt, ra, imm10 And Halfword Immediate
		#1; op = 8'b00010101;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1000000111;

		@(posedge clk);
		// andhi rt, ra, imm10 And Halfword Immediate
		#1; op = 8'b00010100;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1000000111;

		@(posedge clk);
		// andi rt, ra, imm10 And Word Immediate
		#1; op = 8'b00010100;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1000000111;

		@(posedge clk);
		// ori rt, ra, imm10 Or Byte Immediate
		#1; op = 8'b00000110;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
		// orhi rt, ra, imm10 Or Halfword Immediate
		#1; op = 8'b00000101;
			format = 4;
			ra = 128'hFEFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
		// ori rt, ra, imm10 Or Word Immediate
		#1; op = 8'b00000100;
			format = 4;
			ra = 128'hFEFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
		// xorbi rt, ra, imm10 Exclusive Or Byte Immediate
		#1; op = 8'b01000110;
			format = 4;
			ra = 128'hFEFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
 		// xorhi rt, ra, imm10 Xor Halfword Immediate
 		#1; op = 8'b01000101;
			format = 4;
			ra = 128'hFEFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
		// xori rt, ra, imm10 Xor Word Immediate
 		#1; op = 8'b01000100;
			format = 4;
			ra = 128'hFEFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
 		// ceqbi rt, ra, imm10 Compare Equal Byte Immediate
 		#1; op = 8'b01111110;
			format = 4;
			ra = 128'hFEFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
 		// ceqhi rt, ra, imm10 Compare Equal Halfword Immediate
 		#1; op = 8'b01111101;
			format = 4;
			ra = 128'hFEFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1011111111;

		@(posedge clk);
 		// ceqi rt, ra, imm10 Compare Equal Word Immediate
 		#1; op = 8'b01111100;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1111111111;

		@(posedge clk);
		// cgtbi rt, ra, imm10 Compare Greater Than Byte Immediate
 		#1; op = 8'b01001110;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1111111111;
		@(posedge clk);
		// cgthi rt, ra, imm10 Compare Greater Than Halfword Immediate
 		#1; op = 8'b01001101;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFF1FFF;
			imm = 10'b1111111111;
		@(posedge clk);
		// cgti rt, ra, imm10 Compare Greater Than Word Immediate
 		#1; op = 8'b01001100;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFFFFFF1FFF;
			imm = 10'b0111111111;

		@(posedge clk);
		//clgtbi rt, ra, imm10 Compare Logical Greater Than Byte Immediate
 		#1; op = 8'b01011110;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFFFFFF;
			imm = 10'b1101111111;

		@(posedge clk);
		// clgthi rt, ra, imm10 Compare Logical Greater Than Halfword Immediate
 		#1; op = 8'b01001101;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFF7FFF1FFF;
			imm = 10'b1111111111;

		@(posedge clk);
		// clgti rt, ra, imm10 Compare Logical Greater Than Word Immediate

 		#1; op = 8'b01011100;
			format = 4;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFFFFFF1FFF;
			imm = 10'b0111111111;

		@(posedge clk);
		//  ilh rt, imm16 Immediate Load Halfword

 		#1; op = 9'b010000011;
			format = 5;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFFFFFF1FFF;
			imm = 16'b0110011001100110;

		@(posedge clk);
		// iohl rt, imm16 Immediate Or Halfword Lower

 		#1; op = 9'b011000001;
			format = 5;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFFFFFF1FFF;
			imm = 16'b0110011001100110;
			rt_st=128'h0FF0FFFF700F7FFF7FFF7FFFFFFF1000;

		@(posedge clk);
		// ila rt, imm18 Immediate Load Address
		$display("ila rt, imm18 ");
 		#1; op = 7'b0100001;
			format = 6;
			ra = 128'hFFFFFFFF7FFF7FFF7FFF7FFFFFFF1FFF;
			imm = 18'b000110011001100110;
			rt_st=128'h0FF0FFFF700F7FFF7FFF7FFFFFFF1000;

		@(posedge clk);
		#1; op=0;
		@(posedge clk);
		#100; $stop; // Stop simulation
	end
endmodule