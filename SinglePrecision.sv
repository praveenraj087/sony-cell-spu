module SinglePrecision(clk, reset, op, format, rt_addr, ra, rb, rc, imm, reg_write, rt_wb, rt_addr_wb, reg_write_wb, rt_int, rt_addr_int, reg_write_int, branch_taken,
	rt_addr_delay, reg_write_delay, int_delay);
	input			clk, reset;
	
	//RF/FWD Stage
	input [0:10]	op;				//Decoded opcode, truncated based on format
	input [2:0]		format;			//Format of instr, used with op and imm
	input [0:6]		rt_addr;		//Destination register address
	input [0:127]	ra, rb, rc;		//Values of source registers
	input [0:17]	imm;			//Immediate value, truncated based on format
	input			reg_write;		//Will current instr write to RegTable
	input			branch_taken;	//Was branch taken?
	
	//WB Stage
	output logic [0:127]	rt_wb;			//Output value of Stage 6
	output logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	output logic			reg_write_wb;	//Will rt_wb write to RegTable
	
	output logic [0:127]	rt_int;			//Output value of Stage 7
	output logic [0:6]		rt_addr_int;	//Destination register for rt_wb
	output logic			reg_write_int;	//Will rt_wb write to RegTable
	
	//Internal Signals
	logic [6:0][0:127]	rt_delay;			//Staging register for calculated values
	output logic [6:0][0:6]	rt_addr_delay;		//Destination register for rt_wb
	output logic [6:0]		reg_write_delay;	//Will rt_wb write to RegTable
	output logic [6:0]		int_delay;			//1 if int op, 0 if else
	
	always_comb begin
		if (int_delay[5] == 1) begin			//FP7 writeback (only for int ops)
			rt_int = rt_delay[5];
			rt_addr_int = rt_addr_delay[5];
			reg_write_int = reg_write_delay[5];
		end
		else begin
			rt_int = 0;
			rt_addr_int = 0;
			reg_write_int = 0;
		end
		
		if (int_delay[4] == 0) begin			//FP6 writeback
			rt_wb = rt_delay[4];
			rt_addr_wb = rt_addr_delay[4];
			reg_write_wb = reg_write_delay[4];
		end
		else begin
			rt_wb = 0;
			rt_addr_wb = 0;
			reg_write_wb = 0;
		end
	end
	
	always_ff @(posedge clk) begin
		integer scale;
		shortreal tempfp;
		logic [0:15] temp16;
		
		if (reset == 1) begin
			rt_delay[6] <= 0;
			rt_addr_delay[6] <= 0;
			reg_write_delay[6] <= 0;
			int_delay[6] <= 0;
			for (int i=0; i<6; i=i+1) begin
				rt_delay[i] <= 0;
				rt_addr_delay[i] <= 0;
				reg_write_delay[i] <= 0;
				int_delay[i] <= 0;
			end
		end
		else begin
			rt_delay[6] <= rt_delay[5];
			rt_addr_delay[6] <= rt_addr_delay[5];
			reg_write_delay[6] <= reg_write_delay[5];
			int_delay[6] <= int_delay[5];
			for (int i=0; i<5; i=i+1) begin
				rt_delay[i+1] <= rt_delay[i];
				rt_addr_delay[i+1] <= rt_addr_delay[i];
				reg_write_delay[i+1] <= reg_write_delay[i];
				int_delay[i+1] <= int_delay[i];
			end
			
			if (format == 0 && op[0:9] == 0000000000) begin		//nop : No Operation (Execute)
				rt_delay[0] <= 0;
				rt_addr_delay[0] <= 0;
				reg_write_delay[0] <= 0;
				int_delay[0] <= 0;
			end
			else begin
				rt_addr_delay[0] <= rt_addr;
				reg_write_delay[0] <= reg_write;
				if (branch_taken) begin
					int_delay[0] <= 0;
					rt_delay[0] <= 0;
					rt_addr_delay[0] <= 0;
					reg_write_delay[0] <= 0;
				end
				else if (format == 0) begin
					case (op)
						11'b01111000100 : begin					//mpy : Multiply
							int_delay[0] <= 1;
							for (int i=0; i<4; i=i+1)
								rt_delay[0][(i*32) +: 32] <= $signed(ra[(i*32)+16 +: 16]) * $signed(rb[(i*32)+16 +: 16]);
						end
						11'b01111001100 : begin					//mpyu : Multiply Unsigned
							int_delay[0] <= 1;
							for (int i=0; i<4; i=i+1)
								rt_delay[0][(i*32) +: 32] <= $unsigned(ra[(i*32)+16 +: 16]) * $unsigned(rb[(i*32)+16 +: 16]);
						end
						11'b01111000101 : begin					//mpyh : Multiply High
							int_delay[0] <= 1;
							for (int i=0; i<4; i=i+1)
								rt_delay[0][(i*32) +: 32] <= ($signed(ra[(i*32) +: 16]) * $signed(rb[(i*32)+16 +: 16])) << 16;
						end
						11'b01011000100 : begin					//fa : Floating Add
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								if (($bitstoshortreal(ra[(i*32) +: 32]) + $bitstoshortreal(rb[(i*32) +: 32])) >= $bitstoshortreal(32'h7F7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'h7F7FFFFF;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) + $bitstoshortreal(rb[(i*32) +: 32])) <= $bitstoshortreal(32'hFF7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'hFF7FFFFF;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) + $bitstoshortreal(rb[(i*32) +: 32])) <= $bitstoshortreal(32'h00000001)
									&& ($bitstoshortreal(ra[(i*32) +: 32]) + $bitstoshortreal(rb[(i*32) +: 32])) > 0)
									rt_delay[0][(i*32) +: 32] <= 32'h00000001;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) + $bitstoshortreal(rb[(i*32) +: 32])) >= $bitstoshortreal(32'h80000001)
									&& ($bitstoshortreal(ra[(i*32) +: 32]) + $bitstoshortreal(rb[(i*32) +: 32])) < 0)
									rt_delay[0][(i*32) +: 32] <= 32'h80000001;
								else
								rt_delay[0][(i*32) +: 32] <= $shortrealtobits($bitstoshortreal(ra[(i*32) +: 32]) + $bitstoshortreal(rb[(i*32) +: 32]));
							end
						end
						11'b01011000101 : begin					//fs : Floating Subtract
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								if (($bitstoshortreal(ra[(i*32) +: 32]) - $bitstoshortreal(rb[(i*32) +: 32])) >= $bitstoshortreal(32'h7F7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'h7F7FFFFF;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) - $bitstoshortreal(rb[(i*32) +: 32])) <= $bitstoshortreal(32'hFF7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'hFF7FFFFF;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) - $bitstoshortreal(rb[(i*32) +: 32])) <= $bitstoshortreal(32'h00000001)
									&& ($bitstoshortreal(ra[(i*32) +: 32]) - $bitstoshortreal(rb[(i*32) +: 32])) > 0)
									rt_delay[0][(i*32) +: 32] <= 32'h00000001;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) - $bitstoshortreal(rb[(i*32) +: 32])) >= $bitstoshortreal(32'h80000001)
									&& ($bitstoshortreal(ra[(i*32) +: 32]) - $bitstoshortreal(rb[(i*32) +: 32])) < 0)
									rt_delay[0][(i*32) +: 32] <= 32'h80000001;
								else
								rt_delay[0][(i*32) +: 32] <= $shortrealtobits($bitstoshortreal(ra[(i*32) +: 32]) - $bitstoshortreal(rb[(i*32) +: 32]));
							end
						end
						11'b01011000110 : begin					//fm : Floating Multiply
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								if (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) >= $bitstoshortreal(32'h7F7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'h7F7FFFFF;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) <= $bitstoshortreal(32'hFF7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'hFF7FFFFF;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) <= $bitstoshortreal(32'h00000001)
									&& ($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) > 0)
									rt_delay[0][(i*32) +: 32] <= 32'h00000001;
								else if (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) >= $bitstoshortreal(32'h80000001)
									&& ($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) < 0)
									rt_delay[0][(i*32) +: 32] <= 32'h80000001;
								else
								rt_delay[0][(i*32) +: 32] <= $shortrealtobits($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32]));
							end
						end
						11'b01111000010 : begin					//fceq : Floating Compare Equal
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								if ($bitstoshortreal(ra[(i*32) +: 32]) == $bitstoshortreal(rb[(i*32) +: 32]))
									rt_delay[0][(i*32) +: 32] <= 32'hFFFFFFFF;
								else
									rt_delay[0][(i*32) +: 32] <= 0;
							end
						end
						11'b01011000010 : begin					//fcgt : Floating Compare Greater Than
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								if ($bitstoshortreal(ra[(i*32) +: 32]) > $bitstoshortreal(rb[(i*32) +: 32]))
									rt_delay[0][(i*32) +: 32] <= 32'hFFFFFFFF;
								else
									rt_delay[0][(i*32) +: 32] <= 0;
							end
						end
						default begin
							int_delay[0] <= 0;
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
				else if (format == 1) begin
					case (op[7:10])
						4'b1100 : begin					//mpya : Multiply and Add
							int_delay[0] <= 1;
							for (int i=0; i<4; i=i+1)
								rt_delay[0][(i*32) +: 32] <= ($signed(ra[(i*32)+16 +: 16]) * $signed(rb[(i*32)+16 +: 16])) + $signed(rc[(i*32) +: 32]);
						end
						4'b1110 : begin					//fma : Floating Multiply and Add
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) + $bitstoshortreal(rc[(i*32) +: 32])) >= $bitstoshortreal(32'h7F7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'h7F7FFFFF;
								else if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) + $bitstoshortreal(rc[(i*32) +: 32])) <= $bitstoshortreal(32'hFF7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'hFF7FFFFF;
								else if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) + $bitstoshortreal(rc[(i*32) +: 32])) <= $bitstoshortreal(32'h00000001)
									&& (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) + $bitstoshortreal(rc[(i*32) +: 32])) > 0)
									rt_delay[0][(i*32) +: 32] <= 32'h00000001;
								else if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) + $bitstoshortreal(rc[(i*32) +: 32])) >= $bitstoshortreal(32'h80000001)
									&& (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) + $bitstoshortreal(rc[(i*32) +: 32])) < 0)
									rt_delay[0][(i*32) +: 32] <= 32'h80000001;
								else
								rt_delay[0][(i*32) +: 32] <= $shortrealtobits(($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) + $bitstoshortreal(rc[(i*32) +: 32]));
							end
						end
						4'b1111 : begin					//fms : Floating Multiply and Subtract
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) - $bitstoshortreal(rc[(i*32) +: 32])) >= $bitstoshortreal(32'h7F7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'h7F7FFFFF;
								else if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) - $bitstoshortreal(rc[(i*32) +: 32])) <= $bitstoshortreal(32'hFF7FFFFF))
									rt_delay[0][(i*32) +: 32] <= 32'hFF7FFFFF;
								else if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) - $bitstoshortreal(rc[(i*32) +: 32])) <= $bitstoshortreal(32'h00000001)
									&& (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) - $bitstoshortreal(rc[(i*32) +: 32])) > 0)
									rt_delay[0][(i*32) +: 32] <= 32'h00000001;
								else if ((($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) - $bitstoshortreal(rc[(i*32) +: 32])) >= $bitstoshortreal(32'h80000001)
									&& (($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) - $bitstoshortreal(rc[(i*32) +: 32])) < 0)
									rt_delay[0][(i*32) +: 32] <= 32'h80000001;
								else
								rt_delay[0][(i*32) +: 32] <= $shortrealtobits(($bitstoshortreal(ra[(i*32) +: 32]) * $bitstoshortreal(rb[(i*32) +: 32])) - $bitstoshortreal(rc[(i*32) +: 32]));
							end
						end
						default begin
							int_delay[0] <= 0;
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
				else if (format == 3) begin
					case (op[1:10])
						10'b0111011000 : begin					//cflts : Convert Floating to Signed Integer
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								scale = 173 - $unsigned(imm[10:17]);
								if (scale > 127)
									scale = 127;
								else if (scale < 0)
									scale = 0;
								tempfp = $bitstoshortreal(ra[(i*32) +: 32]) * (2**scale);
								if (tempfp > (2**31 - 1))
									rt_delay[0][(i*32) +: 32] <= 32'h7FFFFFFF;
								else if (tempfp < -(2**31))
									rt_delay[0][(i*32) +: 32] <= 32'h80000000;
								else
									rt_delay[0][(i*32) +: 32] <= int'(tempfp);
							end
						end
						10'b0111011001 : begin					//cfltu : Convert Floating to Unsigned Integer
							int_delay[0] <= 0;
							for (int i=0; i<4; i=i+1) begin
								scale = 173 - $unsigned(imm[10:17]);
								if (scale > 127)
									scale = 127;
								else if (scale < 0)
									scale = 0;
								tempfp = $bitstoshortreal(ra[(i*32) +: 32]) * (2**scale);// << scale;
								if (tempfp > (2**31 - 1))
									rt_delay[0][(i*32) +: 32] <= 32'h7FFFFFFF;
								else if (tempfp < 0)
									rt_delay[0][(i*32) +: 32] <= 0;
								else
									rt_delay[0][(i*32) +: 32] <= int'(tempfp);
							end
						end
						default begin
							int_delay[0] <= 0;
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
				else if (format == 4) begin
					case (op[3:10])
						8'b01110100 : begin					//mpyi : Multiply Immediate
							int_delay[0] <= 1;
							for (int i=0; i<4; i=i+1)
								rt_delay[0][(i*32) +: 32] <= $signed(ra[(i*32)+16 +: 16]) * $signed(imm[8:17]);
						end
						8'b01110101 : begin					//mpyui : Multiply Unsigned Immediate
							int_delay[0] <= 1;
							temp16 = $signed(imm[8:17]);
							for (int i=0; i<4; i=i+1)
								rt_delay[0][(i*32) +: 32] <= $unsigned(ra[(i*32)+16 +: 16]) * $unsigned(temp16);
						end
						default begin
							int_delay[0] <= 0;
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
			end
		end
	end
endmodule