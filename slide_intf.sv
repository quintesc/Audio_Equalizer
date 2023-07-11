module slide_intf(clk,rst_n,SS_n,SCLK,MISO,MOSI,POT_LP,POT_B1,POT_B2,POT_B3,POT_HP,VOLUME);
	//////////////////////////////////////////////////////////////
	//  interface to the A2D converter on the DE0-Nano board.  //
	////////////////////////////////////////////////////////////

	input clk,rst_n; 		// clock and active low asynch reset
	input MISO; 			// Serial data in from master

	output SS_n; 			// Active low serf select (to A2D)
	output SCLK; 			// Serial clock (to A2D)
	output MOSI; 			// Serial data out to master
	
	// pot values for each of the sliders
	output reg [11:0] POT_LP;		
	output reg [11:0] POT_B1;
	output reg [11:0] POT_B2;		
	output reg [11:0] POT_B3;
	output reg [11:0] POT_HP;		
	output reg [11:0] VOLUME;	

	// A2D inputs
	logic strt_cnv;			// Asserted for at least one clock cycle to start a conversion
	logic cnvrt;
	logic [2:0] chnnl;		// Specifies which A2D channel (0..7) to conver

	// A2D outputs
	logic cnv_cmplt;		// Asserted by A2D_intf to indicate the conversion has completed. 
	logic [11:0] res;		// The 12-bit result from A2D. (lower 12-bits read from SPI)
	
	/// Instantiate A2D_intf  
	// gets data from sliders
	A2D_intf a2d (.clk(clk),.rst_n(rst_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),.MOSI(MOSI), 
					.cnv_cmplt(cnv_cmplt), .strt_cnv(strt_cnv), .chnnl(chnnl), .res(res));
					


	///// Counter logic /////
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)
			chnnl <= 3'b001;
		else if (cnvrt && chnnl == 3'b001) // all these else if's just control which channel is next based on curr channel
			chnnl <= 3'b000;
		else if (cnvrt && chnnl == 3'b000) 
			chnnl <= 3'b100;
		else if (cnvrt && chnnl == 3'b100) 
			chnnl <= 3'b010;
		else if (cnvrt && chnnl == 3'b010) 
			chnnl <= 3'b011;
		else if (cnvrt && chnnl == 3'b011) 
			chnnl <= 3'b111;
		else if (cnvrt && chnnl == 3'b111) 
			chnnl <= 3'b001;
			
	
	always_ff  @ (posedge clk, negedge rst_n)
		if (!rst_n) begin
			POT_LP <= 12'b000;
			POT_B1 <= 12'b000;			
			POT_B2 <= 12'b000;
			POT_B3 <= 12'b000;			
			POT_HP <= 12'b000;
			VOLUME <= 12'b000;			
		end
		else if (cnvrt) begin
			if (chnnl === 3'b000)	// cascading if else to select correct output based on channel
				POT_B1 <= res;
			else if (chnnl === 3'b001)
				POT_LP <= res;
			else if (chnnl === 3'b010)
				POT_B3 <= res;
			else if (chnnl === 3'b011)
				POT_HP <= res;
			else if (chnnl === 3'b100)
				POT_B2 <= res;
			else if (chnnl === 3'b111)
				VOLUME <= res;
		end
			
	
	//assign chnnl = (cntr !== (3'b101 || 3'b110)) ? cntr : chnnl;
			
			
	  ////////////////////////
	 //// STATE MACHINE /////
	////////////////////////
	typedef enum reg {START, CMPLT} state_t;
	state_t state, nxt_state;
	
	// State synchonizer FF
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n) 
			state <= START;
		else
			state <= nxt_state;
			
			
	// States
	always_comb begin
		strt_cnv = 1'b0;
		cnvrt = 1'b0;
		nxt_state = state;
		
		case (state)
			START: begin
				strt_cnv = 1'b1;
				nxt_state = CMPLT;
			end
			CMPLT: if (cnv_cmplt) begin
				cnvrt = 1'b1;
				nxt_state = START;
			end
			default : nxt_state = START;

		endcase
	end
			
endmodule