module SimpleFixed2(clk, reset, op, format, rt_addr, ra, rb, imm, reg_write, rt_wb, rt_addr_wb, reg_write_wb, branch_taken, rt_addr_delay, reg_write_delay);
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

	logic [6:0]			i;					//7-bit counter for loops
	logic [0:127] tmp,s;

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
			for (i=0; i<3; i=i+1) begin
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
						11'b00001011111 : begin					//shlh : Shift Left Halfword
							for (i=0; i<8; i=i+1) begin
								if ((rb[(i*16) +: 16] & 16'h001F) < 16) begin
									rt_delay[0][(i*16) +: 16] <= ra[(i*16) +: 16] << (rb[(i*16) +: 16] & 16'h001F);
								end
								else
									rt_delay[0][(i*16) +: 16] <= 0;
							end
						end
						11'b00001011011 : begin					//shl rt, ra, rb : Shift Left Word
							for (i=0; i<16; i=i+4) begin
								if ((rb[(i*8) +: 32] & 32'h0000003F) < 32) begin
									rt_delay[0][(i*8) +: 32] = ra[(i*8) +: 32] << (rb[(i*8) +: 32] & 32'h0000003F);
								end
								else begin
									rt_delay[0][(i*8) +: 32] = 0;
								end
							end
						end
						11'b00001011100 : begin					//roth rt, ra, rb : Rotate Halfword
							for(i = 0;i<=15;i=i+2) begin
								tmp[0:15] = ra[(i*8) +: 16];
								for(int b = 0;b<16;b=b+1) begin
									if( ( b+(rb[(i*8) +: 16] & 16'h000F)) < 16 ) begin
										rt_delay[0][(i*8)+b] = tmp[b+(rb[(i*8) +: 16] & 16'h000F)];
									end
									else begin
										rt_delay[0][(i*8)+b] = tmp[b+(rb[(i*8) +: 16] & 16'h000F)-16];
									end
								end
							end
						end
						11'b00001011000 : begin					//rot rt, ra, rb : Rotate Word

							for(i = 0;i<=15;i=i+4) begin
								tmp[0:31] = ra[(i*8) +: 32];
								for(int b = 0;b<32;b=b+1) begin
									if( ( b+(rb[(i*8) +: 32] & 32'h0000001F)) < 32 ) begin
										rt_delay[0][(i*8)+b] = tmp[b+(rb[(i*8) +: 32] & 32'h0000001F)];
									end
									else begin
										rt_delay[0][(i*8)+b] = tmp[b+(rb[(i*8) +: 32] & 32'h0000001F)-32];
									end
								end
							end
						end
						11'b00001011101  : begin					//rothm rt, ra, rb : Rotate and Mask Halfword

							for(i = 0;i<=15;i=i+2) begin
								tmp[0:15] = ra[(i*8) +: 16];
								for(int b = 0;b<16;b=b+1) begin
									if( b > (( 0- rb[(i*8) +: 16] ) & 16'h001F)) begin
										rt_delay[0][(i*8)+b] = tmp[b-(( 0- rb[(i*8) +: 16] ) & 16'h001F)];
									end
									else begin
										rt_delay[0][(i*8)+b] =0;
									end
								end
							end
						end
						11'b00001011001  : begin					//rotm rt, ra, rb : Rotate and Mask Word

							for(i = 0;i<=15;i=i+4) begin
								tmp[0:31] = ra[(i*8) +: 32];
								for(int b = 0;b<32;b=b+1) begin
									if( b > (( 0- rb[(i*8) +: 32] ) & 32'h0000003F)) begin
										rt_delay[0][(i*8)+b] = tmp[b-(( 0- rb[(i*8) +: 32] ) & 32'h0000003F)];
									end
									else begin
										rt_delay[0][(i*8)+b] =0;
									end
								end
							end
						end
						11'b00001011110  : begin					//rotmah rt, ra, rb : Rotate and Mask Algebraic Halfword

							for(i = 0;i<=15;i=i+2) begin
								tmp[0:15] = ra[(i*8) +: 16];
								for(int b = 0;b<16;b=b+1) begin
									if( b >= (( 0- rb[(i*8) +: 16] ) & 16'h001F)) begin
										rt_delay[0][(i*8)+b] = tmp[b-(( 0- rb[(i*8) +: 16] ) & 16'h001F)];
									end
									else begin
										rt_delay[0][(i*8)+b] =tmp[0];
									end
								end
							end
						end
						11'b00001011010  : begin					//rotma rt, ra, rb : Rotate and Mask Algebraic Word

							for(i = 0;i<=15;i=i+4) begin
								tmp[0:31] = ra[(i*8) +: 32];
								for(int b = 0;b<32;b=b+1) begin
									if( b > (( 0- rb[(i*8) +: 32] ) & 32'h0000003F)) begin
										rt_delay[0][(i*8)+b] = tmp[b-(( 0- rb[(i*8) +: 32] ) & 32'h0000003F)];
									end
									else begin
										rt_delay[0][(i*8)+b] =tmp[0];
									end
								end
							end
						end
						default begin
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
				else if (format == 2) begin
					case (op)
						11'b00001111011 : begin	//shli rt, ra, imm7 : Shift Left Word Immediate
							for(int i=0;i<26;i=i+1) begin
								s[i] =  imm[11];
							end
							s[26:31] = imm[11:17];
							for(i = 0;i<=15;i=i+4) begin
								tmp[0:31] = ra[(i*8) +: 32];
								for(int b = 0;b<32;b=b+1) begin
									if( b+(s[0:31] & 32'h0000003F) < 32 ) begin
										rt_delay[0][(i*8)+b] = tmp[b+(s[0:31] & 32'h0000003F)];
									end
									else begin
										rt_delay[0][(i*8)+b] = 0;
									end
								end
							end
						end
	
						11'b00001111100: begin // rothi rt, ra, imm7 :   Rotate Halfword Immediate
							for(int i=0;i<9;i=i+1) begin
								s[i] =  imm[11];
							end
							s[9:15] = imm[11:17];
	
							for(i = 0;i<=15;i=i+2) begin
								tmp[0:15] = ra[(i*8) +: 16];
								for(int b = 0;b<16;b=b+1) begin
									if( ( b+(s[0:15] & 16'h000F)) < 16 ) begin
										rt_delay[0][(i*8)+b] = tmp[b+(s[0:15] & 16'h000F)];
									end
									else begin
										rt_delay[0][(i*8)+b] = tmp[b+(s[0:15] & 16'h000F)-16];
									end
								end
							end
						end
						11'b00001111000 : begin			//roti rt, ra, imm7 : Rotate Word Immediate
							for(int i=0;i<26;i=i+1) begin
								s[i] =  imm[11];
							end
							s[26:31] = imm[11:17];
							for(i = 0;i<=15;i=i+4) begin
								tmp[0:31] = ra[(i*8) +: 32];
								for(int b = 0;b<32;b=b+1) begin
									if( ( b+(s[0:31] & 32'h0000001F)) < 32 ) begin
										rt_delay[0][(i*8)+b] = tmp[b+(s[0:31] & 32'h0000001F)];
									end
									else begin
										rt_delay[0][(i*8)+b] = tmp[b+(s[0:31]  & 32'h0000001F)-32];
									end
								end
							end
						end
						11'b00001111110  : begin	//rotmahi rt, ra, imm7 : Rotate and Mask Algebraic Halfword Immediate
	
							for(int i=0;i<9;i=i+1) begin
								s[i] =  imm[11];
							end
							s[9:15] = imm[11:17];
	
							for(i = 0;i<=15;i=i+2) begin
								tmp[0:15] = ra[(i*8) +: 16];
								for(int b = 0;b<16;b=b+1) begin
									if( b >= ((0-s[0:15]) & 16'h001F)) begin
										rt_delay[0][(i*8)+b] = tmp[b-((0-s[0:15]) & 16'h001F)];
									end
									else begin
										rt_delay[0][(i*8)+b] =tmp[0];
									end
								end
							end
						end
						11'b00001111010 : begin	//rotmai rt, ra, imm7 : Rotate and Mask Algebraic Word Immediate
							for(int i=0;i<26;i=i+1) begin
								s[i] =  imm[11];
							end
							s[26:31] = imm[11:17];
							for(i = 0;i<=15;i=i+4) begin
								tmp[0:31] = ra[(i*8) +: 32];
								for(int b = 0;b<32;b=b+1) begin
									if( b>=((0-s[0:31]) & 32'h0000003F)) begin
										rt_delay[0][(i*8)+b] = tmp[b-((0-s[0:31]) & 32'h0000003F)];
									end
									else begin
										rt_delay[0][(i*8)+b] = tmp[0];
									end
								end
							end
						end
						default begin
							rt_delay[0] = 0;
							rt_addr_delay[0] = 0;
							reg_write_delay[0] = 0;
						end
					endcase
				end
			end
		end
	end

endmodule