module SimpleFixed1(clk, reset, op, format, rt_addr, ra, rb, rt_st, imm, reg_write, rt_wb, rt_addr_wb, reg_write_wb, branch_taken, rt_addr_delay, reg_write_delay);
	input			clk, reset;

	//RF/FWD Stage
	input [0:10]	op;				//Decoded opcode, truncated based on format
	input [2:0]		format;			//Format of instr, used with op and imm
	input [0:6]		rt_addr;		//Destination register address
	input [0:127]	ra, rb, rt_st;		//Values of source registers
	input [0:17]	imm;			//Immediate value, truncated based on format
	input			reg_write;		//Will current instr write to RegTable
	input			branch_taken;	//Was branch taken?

	//WB Stage
	output logic [0:127]	rt_wb;			//Output value of Stage 3
	output logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	output logic			reg_write_wb;	//Will rt_wb write to RegTable

	//Internal Signals
	logic [1:0][0:127]	rt_delay;			//Staging register for calculated values
	output logic [1:0][0:6]	rt_addr_delay;		//Destination register for rt_wb
	output logic [1:0]		reg_write_delay;	//Will rt_wb write to RegTable

	logic [6:0]		i;				//7-bit counter for loops
	logic signed [31:0] max_value_32 = 32'h7FFFFFFF;
	logic signed [31:0] min_value_32 = 32'h80000000;

	logic signed [15:0] max_value_16 = 16'h7FFF;
	logic signed [15:0] min_value_16 = 16'h8000;
	logic signed [0:31] mask = 1 << 31;

	logic [0:128] tmp;

	always_comb begin
		rt_wb = rt_delay[0];
		rt_addr_wb = rt_addr_delay[0];
		reg_write_wb = reg_write_delay[0];
	end

	always_ff @(posedge clk) begin
		if (reset == 1) begin
			rt_delay[1] <= 0;
			rt_addr_delay[1] <= 0;
			reg_write_delay[1] <= 0;
			rt_delay[0] <= 0;
			rt_addr_delay[0] <= 0;
			reg_write_delay[0] <= 0;
			tmp = 0;
		end
		else begin
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
					rt_delay[0] = 0;
					rt_addr_delay[0] = 0;
					reg_write_delay[0] = 0;
				end
				else if (format == 0) begin
					case (op)
						11'b00011001000 : begin					//ah : Add Halfword
							for (i=0; i<16; i=i+1) begin
								if (($signed(ra[(i * 16) +:16]) + $signed(rb[(i * 16) +:16])) >= max_value_16)
									rt_delay[0][(i * 16) +:16] = max_value_16;
								else if (($signed(ra[(i * 16) +:16]) + $signed(rb[(i * 16) +:16])) <= min_value_16)
									rt_delay[0][(i * 16) +:16] = min_value_16;
								else
									rt_delay[0][(i * 16) +:16] = $signed(ra[(i * 16) +:16]) + $signed(rb[(i * 16) +:16]);
							end
						end
						11'b00011000000 : begin					//ah : Add Word
							for (i=0; i<32; i=i+1) begin
								if (($signed(ra[(i * 32) +:32]) + $signed(rb[(i * 32) +:32])) >= max_value_32)
									rt_delay[0][(i * 32) +:32] = max_value_32;
								else if (($signed(ra[(i * 32) +:32]) + $signed(rb[(i * 32) +:32])) <= min_value_32)
									rt_delay[0][(i * 32) +:32] = min_value_32;
								else
									rt_delay[0][(i * 32) +:32] = $signed(ra[(i * 32) +:32]) + $signed(rb[(i * 32) +:32]);
							end
						end
						11'b00001001000 : begin		//sfh rt, ra, rb : Subtract from Halfword
							for (i=0; i<16; i=i+1) begin
								if (($signed(rb[(i * 16) +:16]) - $signed(ra[(i * 16) +:16])) >= max_value_16)
									rt_delay[0][(i * 16) +:16] = max_value_16;
								else if ($signed(rb[(i * 16) +:16]) - $signed(ra[(i * 16) +:16]) <= min_value_16)
									rt_delay[0][(i * 16) +:16] = min_value_16;
								else
									rt_delay[0][(i * 16) +:16] = $signed(rb[(i * 16) +:16]) - $signed(ra[(i * 16) +:16]);
							end
						end
						11'b00001000000 : begin		//sf rt, ra, rb : Subtract from Word
							for (i=0; i<32; i=i+1) begin
								if ($signed(rb[(i * 32) +:32]) - $signed(ra[(i * 32) +:32]) >= max_value_32)
									rt_delay[0][(i * 32) +:32] = max_value_32;
								else if ($signed(rb[(i * 32) +:32]) - $signed(ra[(i * 32) +:32]) <= min_value_32)
									rt_delay[0][(i * 32) +:32] = min_value_32;
								else
									rt_delay[0][(i * 32) +:32] = $signed(rb[(i * 32) +:32]) - $signed(ra[(i * 32) +:32]);
							end
						end
						11'b00011000001 : begin // and
							rt_delay[0] =  ra & rb;
						end
						11'b00001000001 : begin // or
							rt_delay[0] =  ra | rb;
						end
						11'b01001000001 : begin // xor
							rt_delay[0] =  ra ^ rb;
						end
						11'b00011001001 : begin // nand
							rt_delay[0] =  ~(ra & rb);
						end
						11'b01111010000 : begin // ceqb rt, ra, rb Compare Equal Byte
							if(ra==rb) begin
								rt_delay[0]=128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
							end
							else begin
								rt_delay[0]=128'h00000000000000000000000000000000;
							end
						end
						11'b01111001000 : begin // ceqh rt, ra, rb Compare Equal Halfword
							for(int i = 0;i<16;i=i+2) begin
								if(ra[(i*8) +: 16]==rb[(i*8) +: 16]) begin
									rt_delay[0][(i*8) +: 16] = 16'hFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 16] = 16'h0000;
								end
							end

						end
						11'b01111000000 : begin // ceq rt, ra, rb Compare Equal Word
							for(int i = 0;i<16;i=i+4) begin
								if(ra[(i*8) +: 32]==rb[(i*8) +: 32]) begin
									rt_delay[0][(i*8) +: 32] = 32'hFFFFFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 32] = 32'h00000000;
								end
							end
						end
						11'b01001010000 : begin // cgtb rt, ra, rb Compare Greater Than Byte
							for(int i = 0;i<16;i=i+1) begin
								if($signed(ra[(i*8) +: 8])>$signed(rb[(i*8) +: 8])) begin
									rt_delay[0][(i*8) +: 8] = 8'hFF;
								end
								else begin
									rt_delay[0][(i*8) +: 8] = 8'h00;
								end
							end
						end
						11'b01001001000 : begin // cgth rt, ra, rb Compare Greater Than Halfword
							for(int i = 0;i<16;i=i+2) begin
								if($signed(ra[(i*8) +: 16])>$signed(rb[(i*8) +: 16])) begin
									rt_delay[0][(i*8) +: 16] = 16'hFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 16] = 16'h0000;
								end
							end
						end
						11'b01001000000 : begin // cgt rt, ra, rb Compare Greater Than Word
							for(int i = 0;i<16;i=i+4) begin
								if($signed(ra[(i*8) +: 32])>$signed(rb[(i*8) +: 32])) begin
									rt_delay[0][(i*8) +: 32] = 32'hFFFFFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 32] = 32'h00000000;
								end
							end
						end
						11'b01011010000 : begin // clgtb rt, ra, rb Compare Logical Greater Than Byte
							for(int i = 0;i<16;i=i+1) begin
								if(ra[(i*8) +: 8]>rb[(i*8) +: 8]) begin
									rt_delay[0][(i*8) +: 8] = 8'hFF;
								end
								else begin
									rt_delay[0][(i*8) +: 8] = 8'h00;
								end
							end
						end
						11'b01011001000 : begin // clgth rt, ra, rb Compare Logical Greater Than Halfword
							for(int i = 0;i<16;i=i+2) begin
								if(ra[(i*8) +: 16]>rb[(i*8) +: 16]) begin
									rt_delay[0][(i*8) +: 16] = 16'hFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 16] = 16'h0000;
								end
							end
						end
						11'b01011000000 : begin // clgt rt, ra, rb Compare Logical Greater Than Word
							for(int i = 0;i<16;i=i+4) begin
								if(ra[(i*8) +: 32]>rb[(i*8) +: 32]) begin
									rt_delay[0][(i*8) +: 32] = 32'hFFFFFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 32] = 32'h00000000;
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
				else if (format == 4) begin //RI10-type
					case (op)
						8'b00011101 : begin					//ahi rt, ra, imm10 : Add Halfword Immediate

							for (i=0; i<16; i=i+1) begin

								if (($signed(ra[(i * 16) +:16]) + $signed(imm[8:17])) >= max_value_16)
									rt_delay[0][(i * 16) +:16] = max_value_16;
								else if (($signed(ra[(i * 16) +:16]) + $signed(imm[8:17])) <= min_value_16)
									rt_delay[0][(i * 16) +:16] = min_value_16;
								else
									rt_delay[0][(i * 16) +:16] = $signed(ra[(i * 16) +:16]) + $signed(imm[8:17]);
							end
						end
						8'b00011100 : begin					//ai rt, ra, imm10 : Add Word Immediate
							for (i=0; i<4; i=i+1) begin
								if (($signed(ra[(i * 32) +:32]) + $signed(imm[8:17])) >= max_value_32)
									rt_delay[0][(i * 32) +:32] = max_value_32;
								else if (($signed(ra[(i * 32) +:32]) + $signed(imm[8:17])) <= min_value_32)
									rt_delay[0][(i * 32) +:32] = min_value_32;
								else
									rt_delay[0][(i * 32) +:32] = $signed(ra[(i * 32) +:32]) + $signed(imm[8:17]);


							end
						end
						8'b00001101 : begin		//sfhi rt, ra, imm10 : Subtract from Halfword Immediate
							for (i=0; i<16; i=i+1) begin
								if (($signed(imm[8:17]) - $signed(ra[(i * 16) +:16])) >= max_value_16)
									rt_delay[0][(i * 16) +:16] = max_value_16;
								else if (($signed(imm[8:17]) - $signed(ra[(i * 16) +:16])) <= min_value_16)
									rt_delay[0][(i * 16) +:16] = min_value_16;
								else
									rt_delay[0][(i * 16) +:16] = $signed(imm[8:17]) - $signed(ra[(i * 16) +:16]);
							end
						end
						8'b00001100 : begin		//sfi rt, ra, imm10 : Subtract from Word Immediate
							for (i=0; i<32; i=i+1) begin
								if (($signed(imm[8:17]) - $signed(ra[(i * 32) +:32])) >= max_value_32)
									rt_delay[0][(i * 32) +:32] = max_value_32;
								else if (($signed(imm[8:17]) - $signed(ra[(i * 32) +:32])) <= min_value_32)
									rt_delay[0][(i * 32) +:32] = min_value_32;
								else
									rt_delay[0][(i * 32) +:32] = $signed(imm[8:17]) - $signed(ra[(i * 32) +:32]);
							end
						end
						8'b00010110 : begin // andbi rt, ra, imm10 And Byte Immediate
							for(int i=0;i<15;i=i+2) begin
								rt_delay[0][(i*8) +: 16] = ra[(i*8) +: 16] & ((imm[10:17] & 8'hFF) | (imm[9:17] & 8'hFF) <<16) ;
							end
						end

						8'b00010101 : begin // andhi rt, ra, imm10 And Halfword Immediate
							for(int i=0;i<6;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[6:15] = imm[8:17];
							for(int i=0;i<15;i=i+2) begin
								rt_delay[0][(i*8) +: 16] = ra[(i*8) +: 16] & tmp[0:15];
							end
						end
						8'b00010100 : begin // andi rt, ra, imm10 And Word Immediate
							for(int i=0;i<21;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[21:31] = imm[8:17];
							for(int i=0;i<15;i=i+4) begin
								rt_delay[0][(i*8) +: 32] = ra[(i*8) +: 32] & tmp[0:31];
							end
						end

						8'b00000110 : begin // orbi rt, ra, imm10 Or Byte Immediate
							for(int i=0;i<15;i=i+4) begin
								rt_delay[0][(i*8) +: 32] = ra[(i*8) +: 32] | ({(imm[10:17] & 8'hFF) ,(imm[10:17] & 8'hFF),(imm[10:17] & 8'hFF),(imm[10:17] & 8'hFF)}) ;
							end
						end

						8'b00000101 : begin // orhi rt, ra, imm10 Or Halfword Immediate
							for(int i=0;i<6;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[6:15] = imm[8:17];
							for(int i=0;i<15;i=i+2) begin
								rt_delay[0][(i*8) +: 16] = ra[(i*8) +: 16] | tmp[0:15];
							end
						end
						8'b00000100 : begin // ori rt, ra, imm10 Or Word Immediate
							for(int i=0;i<21;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[21:31] = imm[8:17];
							for(int i=0;i<15;i=i+4) begin
								rt_delay[0][(i*8) +: 32] = ra[(i*8) +: 32] | tmp[0:31];
							end
						end


						8'b01000110 : begin // xorbi rt, ra, imm10 Exclusive Or Byte Immediate
							for(int i=0;i<15;i=i+4) begin
								rt_delay[0][(i*8) +: 32] = ra[(i*8) +: 32] ^ ({(imm[10:17] & 8'hFF) ,(imm[10:17] & 8'hFF),(imm[10:17] & 8'hFF),(imm[10:17] & 8'hFF)}) ;
							end
						end

						8'b01000101 : begin // xorhi rt, ra, imm10 Xor Halfword Immediate
							for(int i=0;i<6;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[6:15] = imm[8:17];
							for(int i=0;i<15;i=i+2) begin
								rt_delay[0][(i*8) +: 16] = ra[(i*8) +: 16] ^ tmp[0:15];
							end
						end
						8'b01000100 : begin // xori rt, ra, imm10 Xor Word Immediate
							for(int i=0;i<21;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[21:31] = imm[8:17];
							for(int i=0;i<15;i=i+4) begin
								rt_delay[0][(i*8) +: 32] = ra[(i*8) +: 32] ^ tmp[0:31];
							end
						end

						8'b01111110 : begin // ceqbi rt, ra, imm10 Compare Equal Byte Immediate
							for(int i=0;i<16;i=i+1) begin
								if(ra[(i*8) +: 8] == imm[10:17]) begin
									rt_delay[0][(i*8) +: 8] = 8'hFF;
								end
								else begin
									rt_delay[0][(i*8) +: 8] = 8'h00;
								end
							end
						end


						8'b01111101 : begin // ceqhi rt, ra, imm10 Compare Equal Halfword Immediate
							for(int i=0;i<6;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[6:15] = imm[8:17];

							for(int i=0;i<16;i=i+2) begin
								if(ra[(i*8) +: 16] == tmp[0:15]) begin
									rt_delay[0][(i*8) +: 16] = 16'hFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 16] = 16'h0000;
								end
							end
						end

						8'b01111100 : begin // ceqi rt, ra, imm10 Compare Equal Word Immediate
							for(int i=0;i<22;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[22:31] = imm[8:17];
							for(int i=0;i<16;i=i+4) begin
								if(ra[(i*8) +: 32] == tmp[0:31]) begin
									rt_delay[0][(i*8) +: 32] = 32'hFFFFFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 32] = 32'h00000000;
								end
							end
						end

						8'b01001110 : begin // cgtbi rt, ra, imm10 Compare Greater Than Byte Immediate
							for(int i=0;i<16;i=i+1) begin
								if($signed(ra[(i*8) +: 8]) > $signed(imm[10:17])) begin
									rt_delay[0][(i*8) +: 8] = 8'hFF;
								end
								else begin
									rt_delay[0][(i*8) +: 8] = 8'h00;
								end
							end
						end


						8'b01001101 : begin // cgthi rt, ra, imm10 Compare Greater Than Halfword Immediate
							for(int i=0;i<6;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[6:15] = imm[8:17];
							for(int i=0;i<16;i=i+2) begin
								if($signed(ra[(i*8) +: 16]) > $signed(tmp[0:15])) begin
									rt_delay[0][(i*8) +: 16] = 16'hFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 16] = 16'h0000;
								end
							end
						end

						8'b01001100 : begin // cgti rt, ra, imm10 Compare Greater Than Word Immediate
							for(int i=0;i<22;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[22:31] = imm[8:17];

							for(int i=0;i<16;i=i+4) begin
								if($signed(ra[(i*8) +: 32]) > $signed(tmp[0:31])) begin
									rt_delay[0][(i*8) +: 32] = 32'hFFFFFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 32] = 32'h00000000;
								end
							end
						end


						8'b01011110 : begin //clgtbi rt, ra, imm10 Compare Logical Greater Than Byte Immediate
							for(int i=0;i<16;i=i+1) begin
								if($unsigned(ra[(i*8) +: 8]) > $unsigned(imm[10:17])) begin
									rt_delay[0][(i*8) +: 8] = 8'hFF;
								end
								else begin
									rt_delay[0][(i*8) +: 8] = 8'h00;
								end
							end
						end

						8'b01011101 : begin // clgthi rt, ra, imm10 Compare Logical Greater Than Halfword Immediate
							for(int i=0;i<6;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[6:15] = imm[8:17];
							for(int i=0;i<16;i=i+2) begin
								if($unsigned(ra[(i*8) +: 16]) > $unsigned(tmp[0:15])) begin
									rt_delay[0][(i*8) +: 16] = 16'hFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 16] = 16'h0000;
								end
							end
						end

						8'b01011100 : begin // clgti rt, ra, imm10 Compare Logical Greater Than Word Immediate

							for(int i=0;i<22;i=i+1) begin
								tmp[i] =  imm[8];
							end
							tmp[22:31] = imm[8:17];

							for(int i=0;i<16;i=i+4) begin
								if($unsigned(ra[(i*8) +: 32]) > $unsigned(tmp[0:31])) begin
									rt_delay[0][(i*8) +: 32] = 32'hFFFFFFFF;
								end
								else begin
									rt_delay[0][(i*8) +: 32] = 32'h00000000;
								end
							end

						end
						default begin
							rt_delay[0] = 0;
							rt_addr_delay[0] = 0;
							reg_write_delay[0] = 0;
							tmp=0;
						end
					endcase
				end
				else if (format == 5) begin
					case (op)
						9'b010000011: begin // ilh rt, imm16 Immediate Load Halfword
							for(int i=0;i<16;i=i+2) begin
								rt_delay[0][(i*8) +: 16] = imm[2:17];
							end
						end
						9'b010000010: begin // ilhu rt, imm16 Immediate Load Halfword Upper
							for(int i=0;i<16;i=i+4) begin
								rt_delay[0][(i*8) +: 32] = {imm[2:17],16'h0000};
							end
						end
						9'b010000001: begin // il rt, imm16 Immediate Load Word
							for(int i=0;i<4;i++) begin
								rt_delay[0][(i*32) +: 32] = $signed(imm[2:17]);
							end
						end
						9'b011000001: begin // iohl rt, imm16 Immediate Or Halfword Lower
							for(int i=0;i<16;i=i+4) begin
								rt_delay[0][(i*8) +: 32] = rt_st[(i*8) +: 32] | {16'h0000,imm[2:17]};
							end
						end

						default begin
							rt_delay[0] = 0;
							rt_addr_delay[0] = 0;
							reg_write_delay[0] = 0;
							tmp=0;
						end
					endcase

				end
				else if (format == 6) begin
					case (op)
						7'b0100001: begin // ila rt, imm18 Immediate Load Address
							for(int i=0;i<16;i=i+4) begin
								rt_delay[0][(i*8) +: 32] =  {14'h0000,imm[0:17]};
							end
						end

						default begin
							rt_delay[0] = 0;
							rt_addr_delay[0] = 0;
							reg_write_delay[0] = 0;
							tmp=0;
						end
					endcase
				end
			end
		end
	end
endmodule