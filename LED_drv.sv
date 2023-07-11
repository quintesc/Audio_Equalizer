`default_nettype none
module LED_drv (input wire clk, input wire rst_n, output logic [7:0] LED);

	assign LED = 8'h00;
/*
	localparam TIME_PER_LETTER = 275500000; // in cycles @ 50MHz = 5.51 seconds
	
	typedef enum logic [7:0] {W=8'h58, L=8'h4c, B=8'h42} letter;
	letter curr_letter, next_letter;
	logic [28:0] counter; // count up to 275,500,000 cycles, toggle word selected
	


	// controls LEDs
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			LED <= 0;
		else 
			LED <= curr_letter;
	end
		
	// select word
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			curr_letter <= W;
		else if(counter === TIME_PER_LETTER - 1)
			curr_letter <= next_letter;	
	end
	
	assign next_letter = (curr_letter == W) ? L : 
				(curr_letter == L) ? B : W;
	
	// counter logic to toggle between words
	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			counter <= '0;
		else if(counter === TIME_PER_LETTER)
			counter <= '0;
		else 
			counter <= counter + 1;
	end
*/

endmodule
`default_nettype wire
