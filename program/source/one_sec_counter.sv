//Module to generate the desired Baud Rate or Baud Rate Counter
module One_Sec_Timer (clk, reset, count_en, all_timers_done);
	input	clk, reset, count_en;
	output logic all_timers_done;

	//Parameters to configure the communication
	parameter TIMER_WIDTH = 19;
	parameter TIMER_COUNT = 19'd500000;
	parameter TIMER_TICK_COUNT =  TIMER_COUNT - 1;
	parameter TOTAL_TIMER = 100;
	
	logic [(TIMER_WIDTH - 1):0] time_counter; //To count for 1 Timer
	logic [6:0] total_time_counter; // To count total Timers passed
	logic counting_flag; // Internal signal to indicate when counting should start

    	// Start counting logic - only start when `en` is active
    	always_ff @(posedge clk) begin
        	if (reset) 
            		counting_flag <= 1'b0;
        	else if (count_en) 
            		counting_flag <= 1'b1;  // Start counting when enabled
        	else if (all_timers_done)
            		counting_flag <= 1'b0;  // Stop counting when all bits are done
    	end

	// control time_counter
	always_ff @(posedge clk)
	begin
		if (reset)
			time_counter <= {TIMER_WIDTH{1'b0}};
		else if (~counting_flag)
			time_counter <= {TIMER_WIDTH{1'b0}};
		else if (time_counter == TIMER_TICK_COUNT)
			time_counter <= {TIMER_WIDTH{1'b0}};
		else if (counting_flag) // Increment only when counting is enabled
			time_counter <= time_counter + 1'b1;
	end

	// Control bit counter - counting how many bits have been received or transmitted 
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			total_time_counter <= 4'h0;
		else if (~counting_flag)
			total_time_counter <= 4'h0;
		else if (total_time_counter == TOTAL_TIMER)
			total_time_counter <= 4'h0;
		else if (time_counter == TIMER_TICK_COUNT && counting_flag)
			total_time_counter <= total_time_counter + 4'h1;
	end

	// control all_timers_done signal - to indicate if stop bit is reached
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			all_timers_done <= 1'b0;
		else if (total_time_counter == TOTAL_TIMER)
			all_timers_done <= 1'b1;
		else
			all_timers_done <= 1'b0;
	end

endmodule


