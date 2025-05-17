//Module to generate the desired Baud Rate or Baud Rate Counter
module Baud_Counter (clk, reset, reset_counters, baud_clock_full_cycle_edge, baud_clock_half_cycle_edge, all_bits_done);
	input	clk, reset, reset_counters;
	output logic baud_clock_full_cycle_edge, baud_clock_half_cycle_edge, all_bits_done;

	//Parameters to configure the communication
	parameter BAUD_COUNTER_WIDTH = 9;
	parameter BAUD_COUNT = 9'd434;					// This value will be overwritten
	parameter BAUD_TICK_COUNT =  BAUD_COUNT - 1; //9'd433;
	parameter HALF_BAUD_TICK_COUNT	= BAUD_COUNT / 2; //9'd216;
	parameter DATA_WIDTH = 8;						// This value will be overwritten
	parameter TOTAL_DATA_WIDTH = DATA_WIDTH + 2;
	
	logic [(BAUD_COUNTER_WIDTH - 1):0] baud_counter;	//To generate baud clock to synchronise the tx or rx
	logic [3:0] bit_counter;							//To count the bit received/transmitted

	// control baud_counter
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			baud_counter <= {BAUD_COUNTER_WIDTH{1'b0}};
		else if (reset_counters)
			baud_counter <= {BAUD_COUNTER_WIDTH{1'b0}};
		else if (baud_counter == BAUD_TICK_COUNT)
			baud_counter <= {BAUD_COUNTER_WIDTH{1'b0}};
		else
			baud_counter <= baud_counter + 1'b1;
	end

	// Generate baud_clock_full_cycle_edge signal
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			baud_clock_full_cycle_edge <= 1'b0;
		else if (baud_counter == BAUD_TICK_COUNT)
			baud_clock_full_cycle_edge <= 1'b1;
		else
			baud_clock_full_cycle_edge <= 1'b0;
	end

	// Generate baud_clock_half_cycle_edge signal
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			baud_clock_half_cycle_edge <= 1'b0;
		else if (baud_counter == HALF_BAUD_TICK_COUNT)
			baud_clock_half_cycle_edge <= 1'b1;
		else
			baud_clock_half_cycle_edge <= 1'b0;
	end

	// Control bit counter - counting how many bits have been received or transmitted 
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			bit_counter <= 4'h0;
		else if (reset_counters)
			bit_counter <= 4'h0;
		else if (bit_counter == TOTAL_DATA_WIDTH)
			bit_counter <= 4'h0;
		else if (baud_counter == BAUD_TICK_COUNT)
			bit_counter <= bit_counter + 4'h1;
	end

	// control all_bits_done signal - to indicate if stop bit is reached
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			all_bits_done <= 1'b0;
		else if (bit_counter == TOTAL_DATA_WIDTH)
			all_bits_done <= 1'b1;
		else
			all_bits_done <= 1'b0;
	end

endmodule

