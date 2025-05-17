//Transmitting module
module tx_rs232(clk, reset, transmit_data, tx_en, serial_data_out, transmitting_flag, all_bits_transmitted);
	parameter DATA_WIDTH = 8;
	parameter BAUD_COUNT = 9'd434;

	input clk, reset, tx_en;
	input [DATA_WIDTH:1] transmit_data;
	output logic serial_data_out, transmitting_flag;
	
	logic baud_clock, read_input_en;
	output logic all_bits_transmitted;

	logic [DATA_WIDTH:0] data_out_shift_reg;

	initial
	begin
		serial_data_out <= 1'b1;
		data_out_shift_reg <= {(DATA_WIDTH + 1){1'b1}}; // all ones
	end
	
	// Instantiate Baud Counter for TX
	Baud_Counter #(
	//Passing Parameters between modules
    	.BAUD_COUNT(BAUD_COUNT),   
    	.DATA_WIDTH(DATA_WIDTH)
	) TX_Counter (
	// Inputs
	.clk(clk), .reset(reset), .reset_counters(~transmitting_flag),
	// Outputs
	.baud_clock_full_cycle_edge(baud_clock),
	.baud_clock_half_cycle_edge(),
	.all_bits_done(all_bits_transmitted)
	);

	//Control Transmitting Flag	
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			transmitting_flag <= 1'b0;
		else if (all_bits_transmitted == 1'b1)
			transmitting_flag <= 1'b0;
		else if (tx_en)
			transmitting_flag <= 1'b1;
	end
	
	//Check if still in the TX process
	assign read_input_en = ~transmitting_flag & ~all_bits_transmitted & tx_en;

	// Write the transmitting data to Shift register 
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			data_out_shift_reg <= {(DATA_WIDTH + 1){1'b1}}; // all ones
		else if (read_input_en)
			data_out_shift_reg <= {transmit_data, 1'b0};
		else if (baud_clock)
			data_out_shift_reg <= {1'b1, data_out_shift_reg[DATA_WIDTH:1]};
	end
	
	// Export out signal from the shift register
	always_ff @(posedge clk)
	begin
		if (reset == 1'b1)
			serial_data_out <= 1'b1; 
		else 
			serial_data_out <= data_out_shift_reg[0]; //First in first out (FIFO)
	end
endmodule

