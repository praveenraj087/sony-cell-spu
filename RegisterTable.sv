module RegisterTable(clk, reset, instr_even, instr_odd, ra_even, rb_even, rc_even, ra_odd, rb_odd,
		rt_st_odd, rt_addr_even, rt_addr_odd, rt_even, rt_odd, reg_write_even, reg_write_odd);
	input					clk, reset;
	
	//RF/FWD Stage
	input [0:31]			instr_even, instr_odd;			//Instructions to read from decoder
	output logic [0:127]	ra_even, rb_even, rc_even, ra_odd, rb_odd, rt_st_odd;	//Set all possible register values regardless of format

	//WB Stage
	input [0:6]				rt_addr_even, rt_addr_odd;		//Destination registers to write to
	input [0:127]			rt_even, rt_odd;				//Values to write to destination registers
	input 					reg_write_even, reg_write_odd;	//1 if instr will write to rt, else 0

	logic [0:127] registers [0:127];						//RegFile
	logic [7:0] 			i;								//8-bit counter for reset loop

	always_comb begin
		//All source register addresses are in the same location in all instr, so read no matter what
		rc_even = registers[instr_even[25:31]];
		ra_even = registers[instr_even[18:24]];
		rb_even = registers[instr_even[11:17]];

		ra_odd = registers[instr_odd[18:24]];
		rb_odd = registers[instr_odd[11:17]];
		rt_st_odd = registers[instr_odd[25:31]];

		//Forwarding in case of WAR hazard
		if (reg_write_even == 1) begin
			if (instr_even[25:31] == rt_addr_even)
				rc_even = rt_even;
			if (instr_even[18:24] == rt_addr_even)
				ra_even = rt_even;
			if (instr_even[11:17] == rt_addr_even)
				rb_even = rt_even;
			if (instr_odd[25:31] == rt_addr_even)
				rt_st_odd = rt_even;
			if (instr_odd[18:24] == rt_addr_even)
				ra_odd = rt_even;
			if (instr_odd[11:17] == rt_addr_even)
				rb_odd = rt_even;
		end
		if (reg_write_odd == 1) begin
			if (instr_even[25:31] == rt_addr_odd)
				rc_even = rt_odd;
			if (instr_even[18:24] == rt_addr_odd)
				ra_even = rt_odd;
			if (instr_even[11:17] == rt_addr_odd)
				rb_even = rt_odd;
			if (instr_odd[25:31] == rt_addr_odd)
				rt_st_odd = rt_odd;
			if (instr_odd[18:24] == rt_addr_odd)
				ra_odd = rt_odd;
			if (instr_odd[11:17] == rt_addr_odd)
				rb_odd = rt_odd;
		end
	end
	
	always_ff @(posedge clk) begin
		if(reset == 1)begin
			registers[127] = 0;
			for (i=0; i<127; i=i+1) begin
				registers[i] <= 0;
			end
		end
		else begin
			if (reg_write_even == 1)
				registers[rt_addr_even] <= rt_even;
			if (reg_write_odd == 1)
				registers[rt_addr_odd] <= rt_odd;
		end
	end
endmodule