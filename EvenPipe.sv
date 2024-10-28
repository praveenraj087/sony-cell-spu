module EvenPipe(clk, reset, op, format, unit, rt_addr, ra, rb, rc, imm, reg_write, rt_wb, rt_addr_wb, reg_write_wb, branch_taken, fw_wb, fw_addr_wb, fw_write_wb,
	rt_addr_delay_fp1, reg_write_delay_fp1, int_delay_fp1, rt_addr_delay_fx2, reg_write_delay_fx2, rt_addr_delay_b1, reg_write_delay_b1, rt_addr_delay_fx1, reg_write_delay_fx1);
	input			clk, reset;
	
	//RF/FWD Stage
	input [0:10]	op;				//Decoded opcode, truncated based on format
	input [2:0]		format;			//Format of instr, used with op and imm
	input [1:0]		unit;			//Execution unit of instr (0: FP, 1: FX2, 2: Byte, 3: FX1)
	input [0:6]		rt_addr;		//Destination register address
	input [0:127]	ra, rb, rc;		//Values of source registers
	input [0:17]	imm;			//Immediate value, truncated based on format
	input			reg_write;		//Will current instr write to RegTable
	input			branch_taken;	//Was branch taken?
	
	//WB Stage
	output logic [0:127]	rt_wb;			//Output value of Stage 7
	output logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	output logic			reg_write_wb;	//Will rt_wb write to RegTable
	
	//Internal Signals
	output logic [6:0][0:127]	fw_wb;			//Staging register for forwarded values
	output logic [6:0][0:6]		fw_addr_wb;		//Destination register for rt_wb
	output logic [6:0]			fw_write_wb;	//Will rt_wb write to RegTable
	
	logic [0:10]		fp1_op;			//Multiplexed opcode
	logic [2:0]			fp1_format;		//Multiplexed format
	logic				fp1_reg_write;	//Multiplexed reg_write
	logic [0:127]		fp1_out;		//Output value of fp1 Stage 6
	logic [0:6]			fp1_addr_out;	//Destination register for rt_wb
	logic				fp1_write_out;	//Will rt_wb write to RegTable
	logic [0:127]		fp1_int;		//Output value of fp1 Stage 7
	logic [0:6]			fp1_addr_int;	//Destination register for rt_wb
	logic				fp1_write_int;	//Will rt_wb write to RegTable
	
	logic [0:10]		fx2_op;			//Multiplexed opcode
	logic [2:0]			fx2_format;		//Multiplexed format
	logic				fx2_reg_write;	//Multiplexed reg_write
	logic [0:127]		fx2_out;		//Output value of fx2 Stage 4
	logic [0:6]			fx2_addr_out;	//Destination register for rt_wb
	logic				fx2_write_out;	//Will rt_wb write to RegTable
	
	logic [0:10]		b1_op;			//Multiplexed opcode
	logic [2:0]			b1_format;		//Multiplexed format
	logic				b1_reg_write;	//Multiplexed reg_write
	logic [0:127]		b1_out;			//Output value of b1 Stage 4
	logic [0:6]			b1_addr_out;	//Destination register for rt_wb
	logic				b1_write_out;	//Will rt_wb write to RegTable
	
	logic [0:10]		fx1_op;			//Multiplexed opcode
	logic [2:0]			fx1_format;		//Multiplexed format
	logic				fx1_reg_write;	//Multiplexed reg_write
	logic [0:127]		fx1_out;		//Output value of fx1 Stage 2
	logic [0:6]			fx1_addr_out;	//Destination register for rt_wb
	logic				fx1_write_out;	//Will rt_wb write to RegTable
	
	//Internal Signals for Handling RAW Hazards
	output logic [6:0][0:6]	rt_addr_delay_fp1;		//Destination register for rt_wb
	output logic [6:0]		reg_write_delay_fp1;	//Will rt_wb write to RegTable
	output logic [6:0]		int_delay_fp1;			//Will fp1 write an int result
	
	output logic [3:0][0:6]	rt_addr_delay_fx2;		//Destination register for rt_wb
	output logic [3:0]		reg_write_delay_fx2;	//Will rt_wb write to RegTable
	
	output logic [3:0][0:6]	rt_addr_delay_b1;		//Destination register for rt_wb
	output logic [3:0]		reg_write_delay_b1;		//Will rt_wb write to RegTable
	
	output logic [1:0][0:6]	rt_addr_delay_fx1;		//Destination register for rt_wb
	output logic [1:0]		reg_write_delay_fx1;	//Will rt_wb write to RegTable
	
	
	SinglePrecision fp1(.clk(clk), .reset(reset), .op(fp1_op), .format(fp1_format), .rt_addr(rt_addr), .ra(ra), .rb(rb), .rc(rc), .imm(imm), .reg_write(fp1_reg_write),
		.rt_wb(fp1_out), .rt_addr_wb(fp1_addr_out), .reg_write_wb(fp1_write_out), .rt_int(fp1_int), .rt_addr_int(fp1_addr_int), .reg_write_int(fp1_write_int),
		.branch_taken(branch_taken), .rt_addr_delay(rt_addr_delay_fp1), .reg_write_delay(reg_write_delay_fp1), .int_delay(int_delay_fp1));

	SimpleFixed2 fx2(.clk(clk), .reset(reset), .op(fx2_op), .format(fx2_format), .rt_addr(rt_addr), .ra(ra), .rb(rb), .imm(imm), .reg_write(fx2_reg_write), .rt_wb(fx2_out),
		.rt_addr_wb(fx2_addr_out), .reg_write_wb(fx2_write_out), .branch_taken(branch_taken),
		.rt_addr_delay(rt_addr_delay_fx2), .reg_write_delay(reg_write_delay_fx2));

	Byte b1(.clk(clk), .reset(reset), .op(b1_op), .format(b1_format), .rt_addr(rt_addr), .ra(ra), .rb(rb), .imm(imm), .reg_write(b1_reg_write), .rt_wb(b1_out),
		.rt_addr_wb(b1_addr_out), .reg_write_wb(b1_write_out), .branch_taken(branch_taken),
		.rt_addr_delay(rt_addr_delay_b1), .reg_write_delay(reg_write_delay_b1));

	SimpleFixed1 fx1(.clk(clk), .reset(reset), .op(fx1_op), .format(fx1_format), .rt_addr(rt_addr), .ra(ra), .rb(rb), .rt_st(rc), .imm(imm), .reg_write(fx1_reg_write), .rt_wb(fx1_out),
		.rt_addr_wb(fx1_addr_out), .reg_write_wb(fx1_write_out), .branch_taken(branch_taken),
		.rt_addr_delay(rt_addr_delay_fx1), .reg_write_delay(reg_write_delay_fx1));
		
	
	always_comb begin
		fp1_op = 0;
		fp1_format = 0;
		fp1_reg_write = 0;
		
		fx2_op = 0;
		fx2_format = 0;
		fx2_reg_write = 0;
		
		b1_op = 0;
		b1_format = 0;
		b1_reg_write = 0;
		
		fx1_op = 0;
		fx1_format = 0;
		fx1_reg_write = 0;
		
		
		case (unit)									//Mux to determine which unit will take the instr
			2'b00 : begin							//Instr going to fp1
				fp1_op = op;
				fp1_format = format;
				fp1_reg_write = reg_write;
			end
			2'b01 : begin							//Instr going to fx2
				fx2_op = op;
				fx2_format = format;
				fx2_reg_write = reg_write;
			end
			2'b10 : begin							//Instr going to b1
				b1_op = op;
				b1_format = format;
				b1_reg_write = reg_write;
			end
			2'b11 : begin							//Instr going to fx1
				fx1_op = op;
				fx1_format = format;
				fx1_reg_write = reg_write;
			end
		endcase
	end
		
	always_ff @(posedge clk) begin
		fw_wb[0] <= 0;								//fw0 and fw1 don't exist, just use 0
		fw_addr_wb[0] <= 0;
		fw_write_wb[0] <= 0;
		
		if (reset == 1) begin
			rt_wb <= 0;
			rt_addr_wb <= 0;
			reg_write_wb <= 0;
			for (int i=6; i>0; i=i-1) begin
				fw_wb [i] <= 0;
				fw_addr_wb [i] <= 0;
				fw_write_wb [i] <= 0;
			end
		end
		else begin
			rt_wb <= fw_wb[6];
			rt_addr_wb <= fw_addr_wb[6];
			reg_write_wb <= fw_write_wb[6];
			
			if (fp1_write_int == 1) begin			//Replace fw6 with fp1 if possible
				fw_wb[6] <= fp1_int;
				fw_addr_wb[6] <= fp1_addr_int;
				fw_write_wb[6] <= fp1_write_int;
			end
			else begin
				fw_wb[6] <= fw_wb[5];
				fw_addr_wb[6] <= fw_addr_wb[5];
				fw_write_wb[6] <= fw_write_wb[5];
			end
			
			if (fp1_write_out == 1) begin			//Replace fw6 with fp1 if possible
				fw_wb[5] <= fp1_out;
				fw_addr_wb[5] <= fp1_addr_out;
				fw_write_wb[5] <= fp1_write_out;
			end
			else begin
				fw_wb[5] <= fw_wb[4];
				fw_addr_wb[5] <= fw_addr_wb[4];
				fw_write_wb[5] <= fw_write_wb[4];
			end
			
			fw_wb[4] <= fw_wb[3];
			fw_addr_wb[4] <= fw_addr_wb[3];
			fw_write_wb[4] <= fw_write_wb[3];
			
			if (fx2_write_out == 1) begin			//Replace fw4 with fx2 if possible
				fw_wb[3] <= fx2_out;
				fw_addr_wb[3] <= fx2_addr_out;
				fw_write_wb[3] <= fx2_write_out;
			end
			else if (b1_write_out == 1) begin		//Replace fw4 with b1 if possible
				fw_wb[3] <= b1_out;
				fw_addr_wb[3] <= b1_addr_out;
				fw_write_wb[3] <= b1_write_out;
			end
			else begin
				fw_wb[3] <= fw_wb[2];
				fw_addr_wb[3] <= fw_addr_wb[2];
				fw_write_wb[3] <= fw_write_wb[2];
			end
			
			fw_wb[2] <= fw_wb[1];
			fw_addr_wb[2] <= fw_addr_wb[1];
			fw_write_wb[2] <= fw_write_wb[1];
			
			if (fx1_write_out == 1) begin			//Replace fw2 with fx1 if possible
				fw_wb[1] <= fx1_out;
				fw_addr_wb[1] <= fx1_addr_out;
				fw_write_wb[1] <= fx1_write_out;
			end
			else begin
				fw_wb[1] <= fw_wb[0];
				fw_addr_wb[1] <= fw_addr_wb[0];
				fw_write_wb[1] <= fw_write_wb[0];
			end
		end
	end
	
endmodule