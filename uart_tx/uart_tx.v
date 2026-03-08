/*
 * This file is part of verilog_programming
 *
 * Copyright (C) 2026 Costantino
 *
 * This file is a modified version from: Verilog, Formal Verification and Verilator Beginner's Tutorial
 * Copyright (C) Dan Gisselquist, Ph.D.
 *		 Gisselquist Technology, LLC
 * Licensed under GPLv3 or later.
 *
 * Modifications:
 * - minor modifications
 * - playing with formal methods
 */

`default_nettype none

module uart_tx(clk_i, dat_i, wr_i, busy_o, uart_tx_o);

parameter       [31:0]  CLOCKS_PER_BAUD = 32'd868; //It will be overridden in the testbench anyway
input	wire		clk_i,wr_i;
input	wire	[7:0]	dat_i;
output	wire		uart_tx_o;


output	reg		busy_o;
	reg 	[3:0]	state;
	reg	[8:0]	copy_data;

	reg	[31:0]	counter;
	reg		baud_stb;

localparam IDLE=4'hf, START=4'h0, LAST=4'h8;

initial busy_o = 1'b0;
initial state = IDLE;
initial copy_data = 9'h1ff; //8 bits of data + 1 bit for signaling the start

always @(posedge clk_i)
	if ((wr_i) && !busy_o) //&& baud_stb)		//switch to busy as soon as write req is on and not busy
		{busy_o, state} <= {1'b1, START};
	else if (baud_stb) begin	//clock divider goes into action
		if (state == IDLE)		//from idle remain in idle
			{busy_o, state} <= {1'b0, IDLE};
		else if (state < LAST) begin	//Advance the state
			busy_o <= 1'b1;
			state <= state + 1'b1;
		end else		//reset to idle, wait to release the busy state
			{busy_o, state} <= {1'b1, IDLE};
	end

//
always @(posedge clk_i)
	if ((wr_i)&&!busy_o)	//Start transmission with a 0
		copy_data <= {dat_i,1'b0};
	else if (baud_stb)	//Shift right
		copy_data <= {1'b1,copy_data[8:1]};
	else if ((state == IDLE)||(state>=4'h9)) // && (!wr_i))
		copy_data <= 9'h1ff;


initial baud_stb = 1'b1;
initial counter = 0;

//integer clock divider
always @(posedge clk_i)
	if ((wr_i)&&(!busy_o)) begin
		counter <= CLOCKS_PER_BAUD - 1'b1;
		baud_stb <= 1'b0;
	end
	else if (!baud_stb) begin
		baud_stb <= (counter == 1);
		counter  <= counter - 1'b1;
	end	
	else if (state != IDLE)	begin
                counter <= CLOCKS_PER_BAUD - 1'b1;
		baud_stb <= 1'b0;
	end


//assign the rightmost bit of input data to uart_tx_o
assign uart_tx_o = copy_data[0];

`ifdef FORMAL

`ifdef UART_TX
`define ASSUME assume	//properties of the inputs
`else
`define ASSUME assert	//properties of local state and outputs
`endif
	
	reg		f_past_valid;

initial f_past_valid = 1'b0;
always @(posedge clk_i)
        f_past_valid <= 1'b1;

	reg	[7:0]	fv_data;

initial `ASSUME(!wr_i);
always @(posedge clk_i)
	//added counter !=0 condition so as to take into account the
	//alternation of various characters
//	if ( (f_past_valid) && ($past(wr_i)) && ($past(busy_o)) && (counter !=0) )	begin
	if ( (f_past_valid) && ($past(wr_i)) && ($past(busy_o)) && (uart_tx_o != 0))	begin
		`ASSUME(wr_i == $past(wr_i));
		`ASSUME(dat_i == $past(dat_i));
	end

always @(posedge clk_i)
	assert(counter < CLOCKS_PER_BAUD);

always @(posedge clk_i)
	if ( (f_past_valid) && ($past(counter) != 1'b0) )
		assert(counter == $past(counter - 1'b1));

always @(posedge clk_i)
	assert(baud_stb == (counter == 1'b0));

always @(posedge clk_i)
	if (!baud_stb)
		assert(busy_o);

//contract

always @(posedge clk_i)
	if ((wr_i)&&(!busy_o))
		fv_data <= dat_i;

always @(posedge clk_i)
//	if (baud_stb)
		case(state)
		IDLE:	assert(uart_tx_o == 1'b1);
		START:	assert(uart_tx_o == 1'b0);
		4'h1:	assert(uart_tx_o == fv_data[0]);
		4'h2:	assert(uart_tx_o == fv_data[1]);
		4'h3:	assert(uart_tx_o == fv_data[2]);
		4'h4:	assert(uart_tx_o == fv_data[3]);
		4'h5:	assert(uart_tx_o == fv_data[4]);
		4'h6:	assert(uart_tx_o == fv_data[5]);
		4'h7:	assert(uart_tx_o == fv_data[6]);
		4'h8:	assert(uart_tx_o == fv_data[7]);
		default: assert(0);	//never get the default
		endcase

always @(*)
	//if (baud_stb)
		case(state)
		IDLE:	assert(copy_data == 9'h1ff);
		START:	assert(copy_data == {fv_data,1'b0});
		4'h1:	assert(copy_data == {1'b1,fv_data});
		4'h2:	assert(copy_data == {2'b11,fv_data[7:1]});
		4'h3:	assert(copy_data == {3'b111,fv_data[7:2]});
		4'h4:	assert(copy_data == {4'b1111,fv_data[7:3]});
		4'h5:	assert(copy_data == {5'b1111_1,fv_data[7:4]});
		4'h6:	assert(copy_data == {6'b1111_11,fv_data[7:5]});
		4'h7:	assert(copy_data == {7'b1111_111,fv_data[7:6]});
		4'h8:	assert(copy_data == {8'b1111_1111,fv_data[7]});
		default: assert(0);
		endcase


`endif //FORMAL
endmodule
