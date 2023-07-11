module SPI_mnrch(clk,rst_n,MISO, cmd, snd, SS_n, SCLK, MOSI, done, resp);

  input clk,rst_n;			// 50MHz system clock and reset  
  input MISO;				// serial data out to master
  input [15:0] cmd;			// command to the A2D
  input snd;				// A high for 1 clock period would initiate a SPI transaction
  
  output reg SS_n;			// active low serf select
  output SCLK;				// Serial clock
  output MOSI;				// serial data in from master
  output reg done;			// Asserted when SPI transaction is complete
  output [15:0] resp;		// Data from SPI serf.
  
  reg [15:0] shft_reg;
  reg [4:0] SCLK_div;
  reg [4:0] bit_cnt;
  
  // state machine control signals
  // inputs
  logic done16;
  logic full;
  logic snd;
  
  // outputs
  logic ld_SCLK;
  logic init;
    logic shft;
  logic set_done;
  

  
  /////////////////////
  // SCLK_div logic //
  ///////////////////
  always_ff @(posedge clk) begin
    if (ld_SCLK) 
		SCLK_div <= 5'b10111;
	else 
		SCLK_div <= SCLK_div + 1;
  end
  
  assign shft = (SCLK_div === 5'b10001) ? 1'b1 : 1'b0;
  assign full = (SCLK_div === 5'b11111) ? 1'b1 : 1'b0;
  assign SCLK = SCLK_div[4];
  
  
  /////////////////////
  // bit_cntr logic //
  ///////////////////

    always_ff @(posedge clk) begin
	if (init) 
		bit_cnt <= 5'b00000;
	else if (shft)
		bit_cnt <= bit_cnt + 1;
	end
	
  assign done16 = (bit_cnt === 5'b10000) ? 1'b1 : 1'b0;
  
  
  
  ///////////////////////////
  // shift register logic //
  /////////////////////////

  always_ff @ (posedge clk) begin
    if (init) 
		shft_reg <= cmd;
	else if (shft) 
		shft_reg <= {shft_reg[14:0], MISO};
  end
  
  assign MOSI = shft_reg[15];
  assign resp = shft_reg;
  
  
  ///////////////////////////
  // state machine logic  //
  /////////////////////////


  typedef enum logic [1:0] {IDLE, SENDING, PORCH} state_t;
  state_t nxt_state, state;
  
  always_ff @ (posedge clk) begin
	if (!rst_n) begin
		SS_n <= 1'b1;
		done <= 1'b0;
	end 
	else if (set_done) begin
			SS_n <= 1'b1;
			done <= 1'b1;
		end
	else if (init) begin
			SS_n <= 1'b0;
			done <= 1'b0;
		end
	
  end
  
  always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n) 
			state <= IDLE;
		else
			state <= nxt_state;
  
  always_comb begin
	nxt_state = state;
	init = 0;
	ld_SCLK = 0;
	set_done = 0;
	
	case (state)
	
		IDLE: if (snd) begin
			init = 1;
			ld_SCLK = 1;
			nxt_state = SENDING;
		end	

		
		SENDING: if (done16) begin
			 nxt_state = PORCH;
			end 
		
		
		PORCH: if (full) begin
				set_done = 1;
				nxt_state = IDLE;
				ld_SCLK = 1;	
				
			end
		default nxt_state = IDLE;

	endcase
  end
  
  
endmodule  
  