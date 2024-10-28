module Byte(clk, reset, op, format, rt_addr, ra, rb, imm, reg_write, rt_wb, rt_addr_wb, reg_write_wb, branch_taken, rt_addr_delay, reg_write_delay);
	input			clk, reset;
	
	//RF/FWD Stage
	input [0:10]	op;				//Decoded opcode, truncated based on format
	input [2:0]		format;			//Format of instr, used with op and imm
	input [0:6]		rt_addr;		//Destination register address
	input [0:127]	ra, rb;			//Values of source registers
	input [0:17]	imm;			//Immediate value, truncated based on format
	input			reg_write;		//Will current instr write to RegTable
	input			branch_taken;	//Was branch taken?
	
	//WB Stage
	output logic [0:127]	rt_wb;			//Output value of Stage 3
	output logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	output logic			reg_write_wb;	//Will rt_wb write to RegTable
	
	//Internal Signals
	logic [3:0][0:127]	rt_delay;			//Staging register for calculated values
	output logic [3:0][0:6]	rt_addr_delay;		//Destination register for rt_wb
	output logic [3:0]		reg_write_delay;	//Will rt_wb write to RegTable
	
	logic [3:0]			temp;				//Incrementing counter
	
	always_comb begin
		rt_wb = rt_delay[2];
		rt_addr_wb = rt_addr_delay[2];
		reg_write_wb = reg_write_delay[2];
	end
	
	always_ff @(posedge clk) begin
		if (reset == 1) begin
			
			rt_delay[3] <= 0;
			rt_addr_delay[3] <= 0;
			reg_write_delay[3] <= 0;
			for (int i=0; i<3; i=i+1) begin
				rt_delay[i] <= 0;
				rt_addr_delay[i] <= 0;
				reg_write_delay[i] <= 0;
			end
		end
		else begin
			rt_delay[3] <= rt_delay[2];
			rt_addr_delay[3] <= rt_addr_delay[2];
			reg_write_delay[3] <= reg_write_delay[2];
			rt_delay[2] <= rt_delay[1];
			rt_addr_delay[2] <= rt_addr_delay[1];
			reg_write_delay[2] <= reg_write_delay[1];
			rt_delay[1] <= rt_delay[0];
			rt_addr_delay[1] <= rt_addr_delay[0];
			reg_write_delay[1] <= reg_write_delay[0];
			
			if (format == 0 && op == 0) begin					//nop : No Operation (Execute)
				rt_delay[0] <= 0;
				rt_addr_delay[0] <= 0;
				reg_write_delay[0] <= 0;
			end
			else begin
				rt_addr_delay[0] <= rt_addr;
				reg_write_delay[0] <= reg_write;
				if (branch_taken) begin
					rt_delay[0] <= 0;
					rt_addr_delay[0] <= 0;
					reg_write_delay[0] <= 0;
				end
				else if (format == 0) begin
					case (op)
						11'b01010110100 : begin					//cntb : Count Ones in Bytes
							for (int i=0; i<16; i=i+1) begin
								temp = 0;
								for (int j=0; j<8; j=j+1) begin
									if (ra[(i*8)+j] == 1'b1)
										temp = temp + 1;
								end
								rt_delay[0][(i*8) +: 8] <= temp;
							end
						end
						11'b00011010011 : begin					//avgb : Average Bytes
							for (int i=0; i<16; i=i+1) begin
								rt_delay[0][(i*8) +: 8] <= ({2'b00, ra[(i*8) +: 8]} + {2'b00, rb[(i*8) +: 8]} + 1) >> 1;
							end
						end
						11'b00001010011 : begin					//absdb : Absolute Difference of Bytes
							for (int i=0; i<16; i=i+1) begin
								if ($signed(ra[(i*8) +: 8]) > $signed(rb[(i*8) +: 8]))
									rt_delay[0][(i*8) +: 8] <= $signed(ra[(i*8) +: 8]) - $signed(rb[(i*8) +: 8]);
								else
									rt_delay[0][(i*8) +: 8] <= $signed(rb[(i*8) +: 8]) - $signed(ra[(i*8) +: 8]);
							end
						end
						11'b01001010011 : begin					//sumb : Sum Bytes into Halfwords
							for (int i=0; i<4; i=i+1) begin
								rt_delay[0][(i*32) +: 16] <= $signed(rb[(i*32) +: 8]) + $signed(rb[(i*32)+8 +: 8]) + $signed(rb[(i*32)+16 +: 8]) + $signed(rb[(i*32)+24 +: 8]);
								rt_delay[0][(i*32)+16 +: 16] <= $signed(ra[(i*32) +: 8]) + $signed(ra[(i*32)+8 +: 8]) + $signed(ra[(i*32)+16 +: 8]) + $signed(ra[(i*32)+24 +: 8]);
							end
						end
						default begin
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
				else begin
					rt_delay[0] <= 0;
					rt_addr_delay[0] <= 0;
					reg_write_delay[0] <= 0;
				end
			end
		end
	end
	
endmodule