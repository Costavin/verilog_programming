/*
 * This file is part of verilog_programming
 *
 * Copyright (C) 2026 Costantino
 *
 * This file is a modified version from: Verilog, Formal Verification and Verilator Beginner's Tutorial
 * Copyright (C) Dan Gisselquist, Ph.D.
 *               Gisselquist Technology, LLC
 * Licensed under GPLv3 or later.
 *
 * Modifications:
 * - minor modifications
 * - playing with formal methods
 */

`default_nettype none

module helloworld(clk,
`ifdef  VERILATOR
                o_setup,
`endif
                uart);
        parameter       CLOCK_RATE_HZ = 300_000;
	parameter       BAUD_RATE = 115_200; // 115.2 KBaud

        parameter       INITIAL_UART_SETUP = (CLOCK_RATE_HZ/BAUD_RATE);
`ifdef  VERILATOR
        output  wire    [31:0]  o_setup;
        assign  o_setup = INITIAL_UART_SETUP;
`endif
 

uart_tx	#(.CLOCKS_PER_BAUD(INITIAL_UART_SETUP))
	dut(.clk_i(clk), .wr_i(wrtx), .dat_i(datatx),
	.busy_o(busytx), .uart_tx_o(uart));

input	wire	 	clk;
	reg		wrtx;
	reg	[7:0]	datatx;
	wire		busytx;
output	reg		uart;

	reg	[3:0]	state_tx;
	reg	[23:0]	hz_counter;
	reg		restart_tx;


initial state_tx = 0;
initial restart_tx = 0;
initial hz_counter = 24'h16;
initial wrtx = 0;

always @(posedge clk)
	if ((wrtx)&&!(busytx))
		state_tx <= state_tx + 4'h1;

always @(posedge clk)
	case(state_tx)
	4'h0: datatx <= "H";
	4'h1: datatx <= "e";
	4'h2: datatx <= "l";
	4'h3: datatx <= "l";
	4'h4: datatx <= "o";
	4'h5: datatx <= ",";
	4'h6: datatx <= " ";
	4'h7: datatx <= "w";
	4'h8: datatx <= "o";
	4'h9: datatx <= "r";
	4'ha: datatx <= "l";
	4'hb: datatx <= "d";
	4'hc: datatx <= "!";
	4'hd: datatx <= "\t";
	4'he: datatx <= "\r";
	4'hf: datatx <= "\n";
	endcase

always @(posedge clk)
	if (!restart_tx)
		wrtx <= 1'b1;
	else if ((wrtx)&&(!busytx)&&(state_tx == 4'hf))	//disable wrtx when wrtx and wasnt busy and state is f - stall new transmission up to the restart
		wrtx <= 1'b0;

always @(posedge clk)
	if (hz_counter == 0)
		hz_counter <= CLOCK_RATE_HZ - 1'b1;
	else
		hz_counter <= hz_counter - 1'b1;

always @(posedge clk)
	restart_tx <= (hz_counter == 1);


`ifdef  FORMAL
        reg     f_past_valid;

initial f_past_valid = 1'b0;
always @(posedge clk)
        f_past_valid <= 1'b1;

//Check what's happening here
always @(posedge clk)
	if ((f_past_valid)&&($changed(state_tx)))	//binds a variation of states
		assert(($past(wrtx))&&(!$past(busytx))
			&&(state_tx == $past(state_tx)+4'h1)); 
	else if (f_past_valid)
		assert(($stable(state_tx))&&((!$past(wrtx)))||($past(busytx)));
		//Stable: state_tx == $past(state_tx) - binds and equal state
		//time

always @(posedge clk)
	if ((state_tx != 4'h0))
		assert(wrtx);

always @(posedge clk)
	if ((wrtx)&&!(busytx))
		case(state_tx)
		4'h0: assert(datatx == "H");
		4'h1: assert(datatx == "e");
		4'h2: assert(datatx == "l");
		4'h3: assert(datatx == "l");
		4'h4: assert(datatx == "o");
		4'h5: assert(datatx == ",");
		4'h6: assert(datatx == " ");
		4'h7: assert(datatx == "w");
		4'h8: assert(datatx == "o");
		4'h9: assert(datatx == "r");
		4'ha: assert(datatx == "l");
		4'hb: assert(datatx == "d");
		4'hc: assert(datatx == "!");
		4'hd: assert(datatx == "\t");
		4'he: assert(datatx == "\r");
		4'hf: assert(datatx == "\n");
		endcase
//Assuming the all the inputs have taken place at the right state since inputs
//are hard coded
always @(*)
	if ((wrtx)&&!(busytx))
	case(state_tx)
	4'h0: assume(datatx == "H");
	4'h1: assume(datatx == "e");
	4'h2: assume(datatx == "l");
	4'h3: assume(datatx == "l");
	4'h4: assume(datatx == "o");
	4'h5: assume(datatx == ",");
	4'h6: assume(datatx == " ");
	4'h7: assume(datatx == "w");
	4'h8: assume(datatx == "o");
	4'h9: assume(datatx == "r");
	4'ha: assume(datatx == "l");
	4'hb: assume(datatx == "d");
	4'hc: assume(datatx == "!");
	4'hd: assume(datatx == "\t");
	4'he: assume(datatx == "\r");
	4'hf: assume(datatx == "\n");
	endcase


`endif
endmodule
