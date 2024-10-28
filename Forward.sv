module Forward(clk, reset, instr_even, instr_odd, ra_even, rb_even, rc_even, ra_odd, rb_odd, rt_st_odd, ra_even_fwd, rb_even_fwd, rc_even_fwd, ra_odd_fwd, rb_odd_fwd, rt_st_odd_fwd, fw_even_wb, fw_addr_even_wb, fw_write_even_wb, fw_odd_wb, fw_addr_odd_wb, fw_write_odd_wb);
	input			clk, reset;
	input [0:31]	instr_even, instr_odd;					//Instr from decoder
	
	//Nets from decode logic (Note: Will be placed in decode/hazard unit in final submission)
	input [0:127]	ra_even, rb_even, rc_even, ra_odd, rb_odd, rt_st_odd;	//Register values from RegTable
	
	//Signals for forwarding logic
	input [6:0][0:127]	fw_even_wb, fw_odd_wb;				//Pipe shift registers of values ready to be forwarded
	input [6:0][0:6]	fw_addr_even_wb, fw_addr_odd_wb;	//Destinations of values to be forwarded
	input [6:0]			fw_write_even_wb, fw_write_odd_wb;	//Will forwarded values be writted to reg?
	output logic [0:127]	ra_even_fwd, rb_even_fwd, rc_even_fwd, ra_odd_fwd, rb_odd_fwd, rt_st_odd_fwd;	//Updated input values
	
	always_comb begin
		//Checking inputs for even instr. Compared against FWE0 to FWE6, breaking when match found
		//ra
		if (instr_even[18:24] == fw_addr_even_wb[0] && fw_write_even_wb[0] == 1)
			ra_even_fwd = fw_even_wb[0];
		else if (instr_even[18:24] == fw_addr_odd_wb[0] && fw_write_odd_wb[0] == 1)
			ra_even_fwd = fw_odd_wb[0];
		else if (instr_even[18:24] == fw_addr_even_wb[1] && fw_write_even_wb[1] == 1)
			ra_even_fwd = fw_even_wb[1];
		else if (instr_even[18:24] == fw_addr_odd_wb[1] && fw_write_odd_wb[1] == 1)
			ra_even_fwd = fw_odd_wb[1];
		else if (instr_even[18:24] == fw_addr_even_wb[2] && fw_write_even_wb[2] == 1)
			ra_even_fwd = fw_even_wb[2];
		else if (instr_even[18:24] == fw_addr_odd_wb[2] && fw_write_odd_wb[2] == 1)
			ra_even_fwd = fw_odd_wb[2];
		else if (instr_even[18:24] == fw_addr_even_wb[3] && fw_write_even_wb[3] == 1)
			ra_even_fwd = fw_even_wb[3];
		else if (instr_even[18:24] == fw_addr_odd_wb[3] && fw_write_odd_wb[3] == 1)
			ra_even_fwd = fw_odd_wb[3];
		else if (instr_even[18:24] == fw_addr_even_wb[4] && fw_write_even_wb[4] == 1)
			ra_even_fwd = fw_even_wb[4];
		else if (instr_even[18:24] == fw_addr_odd_wb[4] && fw_write_odd_wb[4] == 1)
			ra_even_fwd = fw_odd_wb[4];
		else if (instr_even[18:24] == fw_addr_even_wb[5] && fw_write_even_wb[5] == 1)
			ra_even_fwd = fw_even_wb[5];
		else if (instr_even[18:24] == fw_addr_odd_wb[5] && fw_write_odd_wb[5] == 1)
			ra_even_fwd = fw_odd_wb[5];
		else if (instr_even[18:24] == fw_addr_even_wb[6] && fw_write_even_wb[6] == 1)
			ra_even_fwd = fw_even_wb[6];
		else if (instr_even[18:24] == fw_addr_odd_wb[6] && fw_write_odd_wb[6] == 1)
			ra_even_fwd = fw_odd_wb[6];
		else
			ra_even_fwd = ra_even;
			
		//rb
		if (instr_even[11:17] == fw_addr_even_wb[0] && fw_write_even_wb[0] == 1)
			rb_even_fwd = fw_even_wb[0];
		else if (instr_even[11:17] == fw_addr_odd_wb[0] && fw_write_odd_wb[0] == 1)
			rb_even_fwd = fw_odd_wb[0];
		else if (instr_even[11:17] == fw_addr_even_wb[1] && fw_write_even_wb[1] == 1)
			rb_even_fwd = fw_even_wb[1];
		else if (instr_even[11:17] == fw_addr_odd_wb[1] && fw_write_odd_wb[1] == 1)
			rb_even_fwd = fw_odd_wb[1];
		else if (instr_even[11:17] == fw_addr_even_wb[2] && fw_write_even_wb[2] == 1)
			rb_even_fwd = fw_even_wb[2];
		else if (instr_even[11:17] == fw_addr_odd_wb[2] && fw_write_odd_wb[2] == 1)
			rb_even_fwd = fw_odd_wb[2];
		else if (instr_even[11:17] == fw_addr_even_wb[3] && fw_write_even_wb[3] == 1)
			rb_even_fwd = fw_even_wb[3];
		else if (instr_even[11:17] == fw_addr_odd_wb[3] && fw_write_odd_wb[3] == 1)
			rb_even_fwd = fw_odd_wb[3];
		else if (instr_even[11:17] == fw_addr_even_wb[4] && fw_write_even_wb[4] == 1)
			rb_even_fwd = fw_even_wb[4];
		else if (instr_even[11:17] == fw_addr_odd_wb[4] && fw_write_odd_wb[4] == 1)
			rb_even_fwd = fw_odd_wb[4];
		else if (instr_even[11:17] == fw_addr_even_wb[5] && fw_write_even_wb[5] == 1)
			rb_even_fwd = fw_even_wb[5];
		else if (instr_even[11:17] == fw_addr_odd_wb[5] && fw_write_odd_wb[5] == 1)
			rb_even_fwd = fw_odd_wb[5];
		else if (instr_even[11:17] == fw_addr_even_wb[6] && fw_write_even_wb[6] == 1)
			rb_even_fwd = fw_even_wb[6];
		else if (instr_even[11:17] == fw_addr_odd_wb[6] && fw_write_odd_wb[6] == 1)
			rb_even_fwd = fw_odd_wb[6];
		else
			rb_even_fwd = rb_even;
		
		//rc
		if (instr_even[25:31] == fw_addr_even_wb[0] && fw_write_even_wb[0] == 1)
			rc_even_fwd = fw_even_wb[0];
		else if (instr_even[25:31] == fw_addr_odd_wb[0] && fw_write_odd_wb[0] == 1)
			rc_even_fwd = fw_odd_wb[0];
		else if (instr_even[25:31] == fw_addr_even_wb[1] && fw_write_even_wb[1] == 1)
			rc_even_fwd = fw_even_wb[1];
		else if (instr_even[25:31] == fw_addr_odd_wb[1] && fw_write_odd_wb[1] == 1)
			rc_even_fwd = fw_odd_wb[1];
		else if (instr_even[25:31] == fw_addr_even_wb[2] && fw_write_even_wb[2] == 1)
			rc_even_fwd = fw_even_wb[2];
		else if (instr_even[25:31] == fw_addr_odd_wb[2] && fw_write_odd_wb[2] == 1)
			rc_even_fwd = fw_odd_wb[2];
		else if (instr_even[25:31] == fw_addr_even_wb[3] && fw_write_even_wb[3] == 1)
			rc_even_fwd = fw_even_wb[3];
		else if (instr_even[25:31] == fw_addr_odd_wb[3] && fw_write_odd_wb[3] == 1)
			rc_even_fwd = fw_odd_wb[3];
		else if (instr_even[25:31] == fw_addr_even_wb[4] && fw_write_even_wb[4] == 1)
			rc_even_fwd = fw_even_wb[4];
		else if (instr_even[25:31] == fw_addr_odd_wb[4] && fw_write_odd_wb[4] == 1)
			rc_even_fwd = fw_odd_wb[4];
		else if (instr_even[25:31] == fw_addr_even_wb[5] && fw_write_even_wb[5] == 1)
			rc_even_fwd = fw_even_wb[5];
		else if (instr_even[25:31] == fw_addr_odd_wb[5] && fw_write_odd_wb[5] == 1)
			rc_even_fwd = fw_odd_wb[5];
		else if (instr_even[25:31] == fw_addr_even_wb[6] && fw_write_even_wb[6] == 1)
			rc_even_fwd = fw_even_wb[6];
		else if (instr_even[25:31] == fw_addr_odd_wb[6] && fw_write_odd_wb[6] == 1)
			rc_even_fwd = fw_odd_wb[6];
		else
			rc_even_fwd = rc_even;
			
		//Checking inputs for odd instr. Compared against FWO0 to FWO6, breaking when match found
		//ra
		if (instr_odd[18:24] == fw_addr_even_wb[0] && fw_write_even_wb[0] == 1)
			ra_odd_fwd = fw_even_wb[0];
		else if (instr_odd[18:24] == fw_addr_odd_wb[0] && fw_write_odd_wb[0] == 1)
			ra_odd_fwd = fw_odd_wb[0];
		else if (instr_odd[18:24] == fw_addr_even_wb[1] && fw_write_even_wb[1] == 1)
			ra_odd_fwd = fw_even_wb[1];
		else if (instr_odd[18:24] == fw_addr_odd_wb[1] && fw_write_odd_wb[1] == 1)
			ra_odd_fwd = fw_odd_wb[1];
		else if (instr_odd[18:24] == fw_addr_even_wb[2] && fw_write_even_wb[2] == 1)
			ra_odd_fwd = fw_even_wb[2];
		else if (instr_odd[18:24] == fw_addr_odd_wb[2] && fw_write_odd_wb[2] == 1)
			ra_odd_fwd = fw_odd_wb[2];
		else if (instr_odd[18:24] == fw_addr_even_wb[3] && fw_write_even_wb[3] == 1)
			ra_odd_fwd = fw_even_wb[3];
		else if (instr_odd[18:24] == fw_addr_odd_wb[3] && fw_write_odd_wb[3] == 1)
			ra_odd_fwd = fw_odd_wb[3];
		else if (instr_odd[18:24] == fw_addr_even_wb[4] && fw_write_even_wb[4] == 1)
			ra_odd_fwd = fw_even_wb[4];
		else if (instr_odd[18:24] == fw_addr_odd_wb[4] && fw_write_odd_wb[4] == 1)
			ra_odd_fwd = fw_odd_wb[4];
		else if (instr_odd[18:24] == fw_addr_even_wb[5] && fw_write_even_wb[5] == 1)
			ra_odd_fwd = fw_even_wb[5];
		else if (instr_odd[18:24] == fw_addr_odd_wb[5] && fw_write_odd_wb[5] == 1)
			ra_odd_fwd = fw_odd_wb[5];
		else if (instr_odd[18:24] == fw_addr_even_wb[6] && fw_write_even_wb[6] == 1)
			ra_odd_fwd = fw_even_wb[6];
		else if (instr_odd[18:24] == fw_addr_odd_wb[6] && fw_write_odd_wb[6] == 1)
			ra_odd_fwd = fw_odd_wb[6];
		else
			ra_odd_fwd = ra_odd;
			
		//rb
		if (instr_odd[11:17] == fw_addr_even_wb[0] && fw_write_even_wb[0] == 1)
			rb_odd_fwd = fw_even_wb[0];
		else if (instr_odd[11:17] == fw_addr_odd_wb[0] && fw_write_odd_wb[0] == 1)
			rb_odd_fwd = fw_odd_wb[0];
		else if (instr_odd[11:17] == fw_addr_even_wb[1] && fw_write_even_wb[1] == 1)
			rb_odd_fwd = fw_even_wb[1];
		else if (instr_odd[11:17] == fw_addr_odd_wb[1] && fw_write_odd_wb[1] == 1)
			rb_odd_fwd = fw_odd_wb[1];
		else if (instr_odd[11:17] == fw_addr_even_wb[2] && fw_write_even_wb[2] == 1)
			rb_odd_fwd = fw_even_wb[2];
		else if (instr_odd[11:17] == fw_addr_odd_wb[2] && fw_write_odd_wb[2] == 1)
			rb_odd_fwd = fw_odd_wb[2];
		else if (instr_odd[11:17] == fw_addr_even_wb[3] && fw_write_even_wb[3] == 1)
			rb_odd_fwd = fw_even_wb[3];
		else if (instr_odd[11:17] == fw_addr_odd_wb[3] && fw_write_odd_wb[3] == 1)
			rb_odd_fwd = fw_odd_wb[3];
		else if (instr_odd[11:17] == fw_addr_even_wb[4] && fw_write_even_wb[4] == 1)
			rb_odd_fwd = fw_even_wb[4];
		else if (instr_odd[11:17] == fw_addr_odd_wb[4] && fw_write_odd_wb[4] == 1)
			rb_odd_fwd = fw_odd_wb[4];
		else if (instr_odd[11:17] == fw_addr_even_wb[5] && fw_write_even_wb[5] == 1)
			rb_odd_fwd = fw_even_wb[5];
		else if (instr_odd[11:17] == fw_addr_odd_wb[5] && fw_write_odd_wb[5] == 1)
			rb_odd_fwd = fw_odd_wb[5];
		else if (instr_odd[11:17] == fw_addr_even_wb[6] && fw_write_even_wb[6] == 1)
			rb_odd_fwd = fw_even_wb[6];
		else if (instr_odd[11:17] == fw_addr_odd_wb[6] && fw_write_odd_wb[6] == 1)
			rb_odd_fwd = fw_odd_wb[6];
		else
			rb_odd_fwd = rb_odd;
		
		//rt_st
		if (instr_odd[25:31] == fw_addr_even_wb[0] && fw_write_even_wb[0] == 1)
			rt_st_odd_fwd = fw_even_wb[0];
		else if (instr_odd[25:31] == fw_addr_odd_wb[0] && fw_write_odd_wb[0] == 1)
			rt_st_odd_fwd = fw_odd_wb[0];
		else if (instr_odd[25:31] == fw_addr_even_wb[1] && fw_write_even_wb[1] == 1)
			rt_st_odd_fwd = fw_even_wb[1];
		else if (instr_odd[25:31] == fw_addr_odd_wb[1] && fw_write_odd_wb[1] == 1)
			rt_st_odd_fwd = fw_odd_wb[1];
		else if (instr_odd[25:31] == fw_addr_even_wb[2] && fw_write_even_wb[2] == 1)
			rt_st_odd_fwd = fw_even_wb[2];
		else if (instr_odd[25:31] == fw_addr_odd_wb[2] && fw_write_odd_wb[2] == 1)
			rt_st_odd_fwd = fw_odd_wb[2];
		else if (instr_odd[25:31] == fw_addr_even_wb[3] && fw_write_even_wb[3] == 1)
			rt_st_odd_fwd = fw_even_wb[3];
		else if (instr_odd[25:31] == fw_addr_odd_wb[3] && fw_write_odd_wb[3] == 1)
			rt_st_odd_fwd = fw_odd_wb[3];
		else if (instr_odd[25:31] == fw_addr_even_wb[4] && fw_write_even_wb[4] == 1)
			rt_st_odd_fwd = fw_even_wb[4];
		else if (instr_odd[25:31] == fw_addr_odd_wb[4] && fw_write_odd_wb[4] == 1)
			rt_st_odd_fwd = fw_odd_wb[4];
		else if (instr_odd[25:31] == fw_addr_even_wb[5] && fw_write_even_wb[5] == 1)
			rt_st_odd_fwd = fw_even_wb[5];
		else if (instr_odd[25:31] == fw_addr_odd_wb[5] && fw_write_odd_wb[5] == 1)
			rt_st_odd_fwd = fw_odd_wb[5];
		else if (instr_odd[25:31] == fw_addr_even_wb[6] && fw_write_even_wb[6] == 1)
			rt_st_odd_fwd = fw_even_wb[6];
		else if (instr_odd[25:31] == fw_addr_odd_wb[6] && fw_write_odd_wb[6] == 1)
			rt_st_odd_fwd = fw_odd_wb[6];
		else
			rt_st_odd_fwd = rt_st_odd;
	end
	
endmodule