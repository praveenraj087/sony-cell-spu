module LocalStore(clk, reset, op, format, rt_addr, ra, rb, rt_st, imm, reg_write, rt_wb, rt_addr_wb, reg_write_wb, branch_taken, rt_addr_delay, reg_write_delay);
	input			clk, reset;
	
	//RF/FWD Stage
	input [0:10]	op;				//Decoded opcode, truncated based on format
	input [2:0]		format;			//Format of instr, used with op and imm
	input [0:6]		rt_addr;		//Destination register address
	input [0:127]	ra, rb, rt_st;	//Values of source registers
	input [0:17]	imm;			//Immediate value, truncated based on format
	input			reg_write;		//Will current instr write to RegTable
	input			branch_taken;	//Was branch taken?
	
	//WB Stage
	output logic [0:127]	rt_wb;			//Output value of Stage 3
	output logic [0:6]		rt_addr_wb;		//Destination register for rt_wb
	output logic			reg_write_wb;	//Will rt_wb write to RegTable
	
	//Internal Signals
	logic [5:0][0:127]	rt_delay;			//Staging register for calculated values
	output logic [5:0][0:6]	rt_addr_delay;		//Destination register for rt_wb
	output logic [5:0]		reg_write_delay;	//Will rt_wb write to RegTable
	
	logic [0:127] mem [0:2047];				//32KB local memory
	
	always_comb begin
		rt_wb = rt_delay[4];
		rt_addr_wb = rt_addr_delay[4];
		reg_write_wb = reg_write_delay[4];
	end
	
	always_ff @(posedge clk) begin
		if (reset == 1) begin
			rt_delay[5] <= 0;
			rt_addr_delay[5] <= 0;
			reg_write_delay[5] <= 0;
			for (int i=0; i<5; i=i+1) begin
				rt_delay[i] <= 0;
				rt_addr_delay[i] <= 0;
				reg_write_delay[i] <= 0;
			end
			for (logic [0:11] i=0; i<2048; i=i+1) begin
				//mem[i] <= 0;
				mem[i] <= {i*4, (i*4 + 1), (i*4 + 2), (i*4 + 3)};
			end
		end
		else begin
			rt_delay[5] <= rt_delay[4];
			rt_addr_delay[5] <= rt_addr_delay[4];
			reg_write_delay[5] <= reg_write_delay[4];
			
			for (int i=0; i<4; i=i+1) begin
				rt_delay[i+1] <= rt_delay[i];
				rt_addr_delay[i+1] <= rt_addr_delay[i];
				reg_write_delay[i+1] <= reg_write_delay[i];
			end
			
			if (format == 0 && op == 0) begin					//nop : No Operation (Load)
				rt_delay[0] <= 0;
				rt_addr_delay[0] <= 0;
				reg_write_delay[0] <= 0;
			end
			else begin
				rt_addr_delay[0] <= rt_addr;
				reg_write_delay[0] <= reg_write;
				if (branch_taken) begin						// If branch taken last cyc, cancel last instr
					rt_delay[0] <= 0;
					rt_addr_delay[0] <= 0;
					reg_write_delay[0] <= 0;
				end
				else if (format == 0) begin
					case (op)
						11'b00111000100 : begin					//lqx : Load Quadword (x-form)
							rt_delay[0] <= mem[$signed(ra[0:31]) + $signed(rb[0:31])];
						end
						11'b00101000100 : begin					//stqx : Store Quadword (x-form)
							mem[$signed(ra[0:31]) + $signed(rb[0:31])] <= rt_st;
							reg_write_delay[0] <= 0;
						end
						default begin
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
				else if (format == 4) begin
					case (op[3:10])
						8'b00110100 : begin					//lqd : Load Quadword (d-form)
							rt_delay[0] <= mem[$signed((ra[0:31]) + $signed(imm[8:17]))];
						end
						8'b00100100 : begin					//stqd : Store Quadword (d-form)
							mem[($signed(ra[0:31]) + $signed(imm[8:17]))] <= rt_st;
							reg_write_delay[0] <= 0;
						end
						default begin
							rt_delay[0] <= 0;
							rt_addr_delay[0] <= 0;
							reg_write_delay[0] <= 0;
						end
					endcase
				end
				else if (format == 5) begin
					case (op[2:10])
						9'b001100001 : begin				//lqa : Load Quadword (a-form)
							rt_delay[0] <= mem[$signed(imm[2:17])];
						end
						9'b001000001 : begin				//stqa : Store Quadword (a-form)
							mem[$signed(imm[2:17])] <= rt_st;
							reg_write_delay[0] <= 0;
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