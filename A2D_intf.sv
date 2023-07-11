module A2D_intf(clk,rst_n,SS_n,SCLK,MISO,MOSI,cnv_cmplt, strt_cnv, chnnl, res);
	//////////////////////////////////////////////////////////////
	//  interface to the A2D converter on the DE0-Nano board.  //
	////////////////////////////////////////////////////////////

	input clk,rst_n; 		// clock and active low asynch reset
	input MISO; 			// Serial data in from master
	input strt_cnv;			// Asserted for at least one clock cycle to start a conversion
	input [2:0] chnnl;		// Specifies which A2D channel (0..7) to conver


	output SS_n; 			// Active low serf select (to A2D)
	output SCLK; 			// Serial clock (to A2D)
	output MOSI; 			// Serial data out to master
	output reg cnv_cmplt;	// Asserted by A2D_intf to indicate the conversion has completed. 
	output [11:0] res;		// The 12-bit result from A2D. (lower 12-bits read from SPI)


	logic [15:0] cmd, resp; // used to send and recieve values from SPI
	logic snd, doneAgain;
	logic done;

	/// Instantiate SPI monarch 
	SPI_mnrch SPI (.clk(clk), .rst_n(rst_n), .MISO(MISO), .cmd(cmd), .snd(snd), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .done(done), .resp(resp));

	// write command in th format given
	assign cmd = {2'b00, chnnl, 11'h000};

	// The 12-bit result from A2D. (lower 12-bits read from SPI)
	assign res = resp [11:0];


	  ////////////////////////
	 //// STATE MACHINE /////
	////////////////////////
	typedef enum reg [1:0] {IDLE, CHNNL, WAIT, RESP} state_t;
	state_t state, nxt_state;
	
	// State synchonizer FF
  always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n) 
			state <= IDLE;
		else
			state <= nxt_state;
			
	// Assures that cnv_cmplt stays up until next strt_cnv
	always_ff @ (posedge clk, negedge rst_n) 
		if (!rst_n)
			cnv_cmplt <= 1'b0;
		else if (strt_cnv)
			cnv_cmplt <= 1'b0;
		else if (doneAgain)
			cnv_cmplt <= 1'b1;
			
			
	// States
	always_comb begin
		snd = 0;
		doneAgain = 0;
		nxt_state = state;
		
		case (state)
			IDLE: if (strt_cnv) begin
				snd = 1;
				nxt_state = CHNNL;
			end
			CHNNL: if (done)
					nxt_state = WAIT;
			WAIT: begin
					nxt_state = RESP;
					snd = 1;
			end
			RESP: if (done) begin
				nxt_state = IDLE;
				doneAgain = 1;
			end
		endcase
	end
			
endmodule