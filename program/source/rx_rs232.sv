//Receiving module
module rx_rs232 (clk, reset, serial_data_in, received_data, receiving_flag, all_bits_received);
	//Parameters to configure the receiving module
	parameter BAUD_COUNT = 9'd434;
	parameter DATA_WIDTH = 8;
	parameter TOTAL_DATA_WIDTH = DATA_WIDTH + 2;

	input clk, reset, serial_data_in;
	output logic receiving_flag; //Receiving Flags: On when receiving, Off when finish
	output logic [(DATA_WIDTH-1):0] received_data;	//Output data from the RX
	
	output logic all_bits_received;

	logic baud_clock; //Use to trigger the shift register (new bit arrived)
	logic [(TOTAL_DATA_WIDTH - 1):0] data_in_shift_reg; //Shift Register

	// Instantiate Baud Counter for RX
	Baud_Counter #(
	//Passing Parameters between modules
    	.BAUD_COUNT(BAUD_COUNT),   
    	.DATA_WIDTH(DATA_WIDTH)
	) RS232_RX_Counter (
	// Inputs
	.clk(clk),
	.reset(reset),
	.reset_counters(~receiving_flag),
	// Outputs
	.baud_clock_full_cycle_edge(), //Full cycle edge of baud clock is not used for RX
	.baud_clock_half_cycle_edge(baud_clock), //Half cycle edge of baud clock is used to synchronise RX 
	.all_bits_done(all_bits_received)
	);
	
	//Control Receiving Flag
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			receiving_flag <= 1'b0;
		else if (all_bits_received == 1'b1) //When all bits are received
			receiving_flag <= 1'b0;	//Turn off the receiving flag
		else if (serial_data_in == 1'b0)
			receiving_flag <= 1'b1;
	end
	
	//Receive data bit by bit and store them into a Shift Register
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			data_in_shift_reg <= {TOTAL_DATA_WIDTH{1'b0}};
		else if (baud_clock)	
			//Shift data to the register to store all bit
			data_in_shift_reg <= {serial_data_in, data_in_shift_reg[(TOTAL_DATA_WIDTH - 1):1]};	
	end

	//Once all bits are received, export the output out
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			received_data <= {DATA_WIDTH{1'b0}};
		else if (receiving_flag==1'b0) //Reach the stop bit
		begin
			received_data <= data_in_shift_reg[DATA_WIDTH:1]; //Export data from shift register to the output 
		end
	end
endmodule

