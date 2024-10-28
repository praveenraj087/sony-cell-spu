module tb_SimpleFixed2();
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

	SimpleFixed2 dut(clk, reset, op, format, rt_addr, ra, rb, imm, reg_write, rt_wb,
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
		// for (int i=0; i<8; i++)
		// 	rb[i*16 +:16] = rb[i*16 +:16] + 1;
	end

	initial begin
		reset = 1;
		format = 3'b000;
		op = 11'b00001011111;						//shlh
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
		#1; op = 11'b00001011111;
		@(posedge clk);
		//#1; op = 0;
		@(posedge clk);
		#1; op = 11'b00001011111;
		@(posedge clk);
		//#1; op = 0;
		@(posedge clk);
		#1; op = 11'b00001011111;
		@(posedge clk);
		#1;
		op = 11'b00001011011;
		rb = 128'h00010001000100010001000100010001;
		ra = 128'h00010001000100010001000100010001;
		@(posedge clk);
		#1;
		op = 11'b00001011100;
		rb = 128'h00010001000100010001000100010001;
		ra = 128'h00020002000200020001000100010001;

		@(posedge clk);
		#1;
		op = 11'b00001011000;
		rb = 128'h00010002000100030001000400010001;
		ra = 128'h00020002000200020001000100010001;

		@(posedge clk);
		#1;
		op = 11'b00001011000;
		rb = 128'h0001000E00010003000100040001000B;
		ra = 128'h000200020002000200010001EFFF0001;

		@(posedge clk);
		#1;
		//rothm rt, ra, rb : Rotate and Mask Halfword
		op = 11'b00001011101;
		rb = 128'h001E000E00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//rotm rt, ra, rb : Rotate and Mask Word
		op = 11'b00001011001;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//rotmah rt, ra, rb : Rotate and Mask Algebraic Halfword
		op = 11'b00001011110;
		rb = 128'h001E000E00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;
		@(posedge clk);
		#1;
		//rotma rt, ra, rb : Rotate and Mask Algebraic Word
		op = 11'b00001011010;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;


		@(posedge clk);
		#1;
		// rothi rt, ra, imm7 :   Rotate Halfword Immediate
		op = 11'b00001111100;
		format=2;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		// rothi rt, ra, imm7 :   Rotate Halfword Immediate
		op = 11'b00001111100;
		format=2;
		imm=1;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;


		@(posedge clk);
		#1;
		//roti rt, ra, imm7 : Rotate Word Immediate
		op = 11'b00001111000;
		format=2;
		imm=0;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//roti rt, ra, imm7 : Rotate Word Immediate
		op = 11'b00001111000;
		format=2;
		imm=1;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//rotmahi rt, ra, imm7 : Rotate and Mask Algebraic Halfword Immediate
		op = 11'b00001111110;
		format=2;
		imm=0;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//rotmahi rt, ra, imm7 : Rotate and Mask Algebraic Halfword Immediate
		op = 11'b00001111110;
		format=2;
		imm=1;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;


		@(posedge clk);
		#1;
		//rotmai rt, ra, imm7 : Rotate and Mask Algebraic Word Immediate
		op = 11'b00001111010;
		format=2;
		imm=0;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//rotmai rt, ra, imm7 : Rotate and Mask Algebraic Word Immediate
		op = 11'b00001111010;
		format=2;
		imm=30;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//shli rt, ra, imm7 : Shift Left Word Immediate
		op = 11'b00001111011;
		format=2;
		imm=0;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;

		@(posedge clk);
		#1;
		//shli rt, ra, imm7 : Shift Left Word Immediate
		op = 11'b00001111011;
		format=2;
		imm=16;
		rb = 128'h001E003A00010003000100040001000B;
		ra = 128'hFFFF00020003000400050006EFFF0001;



		@(posedge clk);
		#1; op = 0;
		@(posedge clk);
		#100; $stop; // Stop simulation
	end
endmodule