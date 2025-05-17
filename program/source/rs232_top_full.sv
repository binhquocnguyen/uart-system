module rs232_top_full(iCLK_50, iKEY, oHEX0, oHEX1, oLEDR, oUART_TXD, iUART_RXD,
	GPIO_oUART_TXD, GPIO_receiving_flag, GPIO_transmitting_flag, GPIO_timer_flag, GPIO_all_bits_received_and_transmitted);
	input iCLK_50;
	input [3:0] iKEY; // For Reset/Send Buttons
  	output oUART_TXD; // UART TX Pin
	input  iUART_RXD; // UART RX Pin
  	output [6:0] oHEX0, oHEX1; 
	output [8:0] oLEDR;  
	
	// Variables for data 
	parameter DATA_WIDTH = 8;
	logic [DATA_WIDTH-1:0] received_data;	
	logic receiving_flag, transmitting_flag;
	logic tx_en, timer_flag, reset; //timer_flag generated after Timer finished, then passed into tx_en as a trigger for TX
	logic all_bits_received, all_bits_transmitted, all_bits_received_and_transmitted; //all_bits_received_and_transmitted is the trigger for Timer to start
	logic [3:0] send_counter; // count transmitting time
	
	// Reset signal via KEY 0
	assign reset = ~iKEY[0];

	// Flags to indicate the process
	assign oLEDR[7] = transmitting_flag;
	assign oLEDR[6] = receiving_flag;
	assign oLEDR[3] = ~receiving_flag; // == received_flag
	
	output logic GPIO_oUART_TXD, GPIO_receiving_flag, GPIO_transmitting_flag, GPIO_timer_flag, GPIO_all_bits_received_and_transmitted;
	assign GPIO_oUART_TXD = oUART_TXD; //GPIO[5]
	assign GPIO_receiving_flag = receiving_flag; //GPIO[2]
	assign GPIO_transmitting_flag = transmitting_flag; //GPIO[4]
	assign GPIO_all_bits_received_and_transmitted = all_bits_received_and_transmitted; //GPIO[6]
	assign GPIO_timer_flag = timer_flag; //GPIO[8]

	//Delete oneshot module, tx_en is triggered by timer_flag

	//Instantiate RX module
	rx_rs232 DUT_RX( 	
	// Inputs
	.clk(iCLK_50),
	.reset(reset),
	.serial_data_in(iUART_RXD), // iUART_RXD
	// Outputs
	.received_data(received_data),
	//.received_flag(received_flag),
	.receiving_flag(receiving_flag),
	.all_bits_received(all_bits_received)
	);

	//Display received data on HEX
	hex_7seg DUT_HEX0(received_data[3:0],oHEX0); 
	hex_7seg DUT_HEX1(received_data[7:4],oHEX1);

	//Instantiate TX module
	tx_rs232 DUT_TX(
	//Inputs
	.clk(iCLK_50),
	.reset(reset),	
	.transmit_data(received_data), // We resend the data received ealier 
	.tx_en(tx_en),
	// Outputs
	.serial_data_out(oUART_TXD), // oUART_TXD
	.transmitting_flag(transmitting_flag),
	.all_bits_transmitted(all_bits_transmitted)
	);

	// Control send counter - counting how many bits have been received or transmitted 
	always_ff @(posedge iCLK_50)
	begin
		if (reset == 1'b1)
			send_counter <= 4'h0;
		else if (receiving_flag) // Reset when having new received 
			send_counter <= 4'h0;
		else if (send_counter >= 4) // Keep unchanged until next receive
			send_counter <= 4'h4;
		else if (timer_flag)
			send_counter <= send_counter + 4'h1;
	end
	
	always_ff @(posedge iCLK_50) begin
        	if (send_counter < 4) begin
           		tx_en = timer_flag; // To trigger TX from Timer
				all_bits_received_and_transmitted = all_bits_received || all_bits_transmitted; // To trigger Timer from TX and RX
        	end else begin
            		tx_en = 1'b0; // Disable transmission after sending 4 times
       		end
    	end
	
	// Instantiate Timer module
	One_Sec_Timer DUT_Timer(
	// Inputs
	.clk(iCLK_50), 
	.reset(reset), 
	.count_en(all_bits_received_and_transmitted), 
	// Outputs
	.all_timers_done(timer_flag)
	);
endmodule