module tb_RegisterTable();

    logic			clk, reset;
	logic [0:31]	instr_even, instr_odd;			//Instructions to read from decoder
	logic [0:127]	ra_even, rb_even, rc_even, ra_odd, rb_odd;	//Set all possible register values regardless of format

	logic [0:6]		rt_addr_even, rt_addr_odd;		//Destination registers to write to
	logic [0:127]	rt_even, rt_odd;				//Values to write to destination registers
	logic			reg_write_even, reg_write_odd;	//1 if instr will write to rt, else 0

	RegisterTable dut (clk, reset, instr_even, instr_odd, ra_even, rb_even, rc_even, ra_odd, rb_odd,
		rt_st_odd, rt_addr_even, rt_addr_odd, rt_even, rt_odd, reg_write_even, reg_write_odd);

    initial
        clk = 0;

    always begin
		#5 clk = ~clk;
        $display("%0t: reset = %h, instr_even = %b instr_odd = %b ra_even = %h rb_even = %h rc_even = %h ra_odd = %h rb_odd = %h rt_addr_even = %h rt_addr_odd = %h rt_even = %h rt_odd = %h reg_write_even = %h reg_write_odd = %h",$time, reset , instr_even, instr_odd,
        ra_even, rb_even, rc_even, ra_odd, rb_odd,rt_addr_even, rt_addr_odd, rt_even, rt_odd,
        reg_write_even, reg_write_odd);
    end

    initial begin
		reset = 1;
		reg_write_even = 0;
		instr_even = 32'h00000000;

        #6;
		reset = 0;											//@11ns, enable unit
		
		@(posedge clk); #1;
		
		@(posedge clk); #1;
		reg_write_even = 1;
		instr_even = 32'b00001011111000001100001000000101; 	//shlh rb=3 ra =4 rt=5
		rt_addr_even = 7'b000101;
		rt_even = 128'h000A000000000000000000000000000;

		instr_odd = 32'b00000000010000000000000000000; 		//lnop
		reg_write_odd = 0;
		rt_addr_odd = 7'b0000000;

		// At address 7 we write the value rt_even
		@(posedge clk) #1;
		// We try to read the value at address 7 for odd pipe and even pipe is also writing back to same
		// register file (7)
		// Odd pipe is able to read the value from reg 7 before even pipe write back new value to it.

		reg_write_even = 1;
		instr_even = 32'b00001011111000001100001000000101; 		//shlh rb=3 ra =4 rt=5
		instr_odd = 32'b00111011011000000100001010000111; 		//shlqi rb=2 ra =5 rt=7
		rt_addr_even = 7'b0000101;
		rt_addr_odd = 7'b0000101;

		rt_even = 128'h000C000000000000000000000000000;
		rt_odd = 128'h000B000000000000000000000000000;
		
		@(posedge clk) #1
		assert(ra_odd == rt_even)
		else
		$display("Hazard");
		
		@(posedge clk ) #8
		$stop; // Stop simulation
    end
endmodule