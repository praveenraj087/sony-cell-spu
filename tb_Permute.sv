module tb_Permute();
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

	Permute dut(clk, reset, op, format, rt_addr, ra, rb, imm, reg_write, rt_wb,
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
		for (int i=0; i<8; i++)
			rb[i*16 +:16] = rb[i*16 +:16] + 1;
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
		#1; op = 11'b00111011011;
		@(posedge clk);
		//#1; op = 0;
		@(posedge clk);
		#1; op = 11'b00111011011;
		@(posedge clk);
		//#1; op = 0;
		@(posedge clk);
		#1; op = 11'b00111011011;
		ra = 128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE;
		@(posedge clk);
		#1; ra = 128'h00101131337377F7FF000000000000FF;
		@(posedge clk);
		#1; op = 11'b00111011111;
		ra = 128'hAFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE;
		@(posedge clk);
		#1;

		// Testcase for rotqbi rt, ra, rb : Rotate Quadword by Bits
		// Rotating the bits by 3 bits rb[29:31]=>3 bits
		rb = 128'h00010011000100010001000100010001;	//Halfwords: 16'h0001
		ra = 128'hBFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFE;
		op = 11'b00111011000;
		rt_addr = 7'b0000101;						//RT = $r5


		@(posedge clk);
		#1;
		op = 11'b00111011100;
		rt_addr = 7'b0000110;						//RT = $r6
		rb = 128'h00000000020000000000000000000000;	//Halfwords: 16'h0001
		ra = 128'hCEEFFFFFFFFFFFFFFFFFFFFFFFFFFEEE;

		@(posedge clk);
		#1;
		//gbb rt,ra Gather Bits from Bytes
		op = 11'b00110110010;
		rt_addr = 7'b0000110;						//RT = $r6
		ra = 128'hCEEFCACEAFBFCFDFABCDEFABCDEFFEEE;

		@(posedge clk);
		#1;
		//gbb rt,ra Gather Bits from halfwords
		op = 11'b00110110001;
		rt_addr = 7'b0000110;						//RT = $r6
		ra = 128'hCEEFCACEAFBFCFDFABCDEFABCDEFFEEE;


		@(posedge clk);
		#1;
		//gb rt, ra Gather Bits from Words
		op = 11'b00110110000;
		rt_addr = 7'b0000110;						//RT = $r6
		ra = 128'hCEEFCACEAFBFCFDFABCDEFABCDEFFEEE;


		@(posedge clk);
		#1;
		//shlqbii rt,ra,value Shift Left Quadword by Bits Immediate
		op = 11'b00111111011;
		rt_addr = 7'b0000110;						//RT = $r6
		format = 2; 								//RI7-type
		imm = 7'b0000011;							// imm7 = 3
		ra = 128'hCEEFFFFFFFFFFFFFFFFFFFFFFFFFFEEE;

		@(posedge clk);
		#1;
		//rotqbii rt, ra, imm7 Rotate Quadword by Bits Immediate
		op = 11'b00111111000;
		rt_addr = 7'b0000110;						//RT = $r6
		format = 2; 								//RI7-type
		imm = 7'b0000011;							// imm7 = 3
		ra = 128'hCEEFFFFFFFFFFFFFFFFFFFFFFFFFFEEE;

		@(posedge clk);
		#1;
		//rotqbyi rt, ra, imm7 Rotate Quadword by Bytes Immediate
		op = 11'b00111111100;
		rt_addr = 7'b0000110;						//RT = $r6
		format = 2; 								//RI7-type
		imm = 7'b0000011;							// imm7 = 3
		ra = 128'hCEEFFFFFFFFFFFFFFFFFFFFFFFFFFEEE;

		@(posedge clk);
		#1;
		op=0;
		#100; $stop; // Stop simulation
	end
endmodule