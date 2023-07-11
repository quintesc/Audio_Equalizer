module band_scale (POT, audio, scaled, clk, rst_n);


	input wire clk, rst_n;
	input wire unsigned [11:0] POT;			// (unsigned) reading from the slide potentiometer
	input wire signed [15:0] audio;		// (signed) signal coming from a FIR filter
	output wire signed [15:0] scaled;	// (signed) output that is the scaled result of the input audio 
	
	logic tooNeg;
	logic tooPos;
	
	logic unsigned [23:0] POTsqr;	
	logic signed [12:0] scaleFactor;
	logic signed [28:0] reading;
	
	
//////////////////////////////////
///////// scaling logic //////////
//////////////////////////////////

//flip flopped for synthesis timing & area
always @(posedge clk, negedge rst_n) 
	if(!rst_n)
		POTsqr <= '0;
	else
		POTsqr <= POT * POT;
		
always @(posedge clk, negedge rst_n) 
	if(!rst_n)
		reading <= '0;
	else
		reading <= scaleFactor * audio;
	
// square potentiometer reading
//assign POTsqr = POT * POT;
assign scaleFactor = {1'b0, POTsqr[23:12]};
//assign reading = scaleFactor * audio;


//////////////////////////////////
//////// saturation logic ////////
//////////////////////////////////

// check if number is negative & there is a zero in 3MSB bits
assign tooNeg = ((reading[28]) && (~&reading[28:25])) ? 1: 0;

// check if number is too positive & there is a one in 5MSB bits
assign tooPos = ((~reading[28]) && (|reading[28:25])) ? 1: 0;

assign scaled = (tooPos) ? 16'h7FFF : 
				(tooNeg) ? 16'h8000 : 
				 reading[25:10];
				 
				 
endmodule