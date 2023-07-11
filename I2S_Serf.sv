`default_nettype none

module I2S_Serf(clk,rst_n,I2S_sclk,I2S_data,I2S_ws,lft_chnnl,rght_chnnl, vld);

  input wire clk,rst_n;			// clk and active low reset
  input wire I2S_sclk;		// 2.11MHz 24 clocks high, 24 clocks low
  input wire I2S_data;			// capture data at rising edge detect
  input wire I2S_ws;			// 0 => left,  1 => right
  output logic [23:0] lft_chnnl;	// parallel 24-bit representation of left audio channel data
  output logic [23:0] rght_chnnl;	// parallel 24-bit representation of right audio channel data
  output logic vld;			// asserted when both lft_chnnl and rght_chnnl values are valid
  
  
  reg [4:0] bit_cntr;		// 5 bit register for the counter
  reg [47:0] shft_reg;		// 48 bit register, has both left and right channels
  // (SM input) internal signals for synchronizing sclk rise
  logic sclk_rise, sclk_1, sclk_2, sclk_3;
  
  // (SM input) internal signal for synchronizing sclk fall
  logic ws_fall, ws_1, ws_2, ws_3;
  // (SM output) clears the bit counter
  logic clr_cnt;

  ///// Counter logic /////
  always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)
			bit_cntr <= 5'b00000;
		else if (clr_cnt)
			bit_cntr <= 5'b00000;
		else if (sclk_rise) 
			bit_cntr <= bit_cntr + 1;
		

  // (SM inputs) flags used to see where in the transmission we are
  logic eq22, eq23, eq24;
  assign eq22 = (bit_cntr === 22);
  assign eq23 = (bit_cntr === 23);
  assign eq24 = (bit_cntr === 24);


  ///// Shifter Logic /////
  always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n)
			shft_reg <= 48'h00000;
		else if (sclk_rise) 
			shft_reg <= {shft_reg[46:0], I2S_data};


  assign lft_chnnl = shft_reg[47:24];
  assign rght_chnnl = shft_reg[23:0];

  
  ///// Rising Edge detect for SCLK /////
  always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			sclk_3 <= 1'b0;
			sclk_2 <= 1'b0;
			sclk_1 <= 1'b0;
		end else begin
		
		sclk_3 <= sclk_2;
		
		sclk_2 <= sclk_1;
		
		sclk_1 <= I2S_sclk;
		
		end
  end
  
  assign sclk_rise = (sclk_2 & ~sclk_3);
  
  ///// Falling Edge detect for WS /////
  always_ff @ (posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			ws_3 <= 1'b0;
			ws_2 <= 1'b0;
			ws_1 <= 1'b0;
		end else begin
		ws_3 <= ws_2;
		
		ws_2 <= ws_1;
		
		ws_1 <= I2S_ws;
		
		end
  end
  
  assign ws_fall = (~ws_2 & ws_3);
  
  
  //////// State Macine //////////
  typedef enum reg [1:0] {IDLE, PORCH, TRSMT_LFT, TRSMT_RGHT} state_t;
  
  state_t state, nxt_state;
  
  // (SM input) asserted when the counter and value of the word select are not as expected
  wire outOfSync = ((eq22 & !ws_2) | (eq23 & ws_2)) & sclk_rise;
  
  ////// Infer state flops ///////
  always_ff @(posedge clk, negedge rst_n)
    if (!rst_n)
      state <= IDLE;
    else
      state <= nxt_state;
  
  always_comb begin
	// default values
  	nxt_state = state;
	vld = 0;
	clr_cnt = 0;
	
	case (state)
		// stay in idle until word select falls
		IDLE: if (ws_fall) begin
				nxt_state = PORCH;
		end	
		
		// account for frontporch until sclk rises
		PORCH: if (sclk_rise) begin
				 clr_cnt = 1;
				 nxt_state = TRSMT_LFT;
			
			end 	
		// start shifting for 24 cycles and then clear count
		TRSMT_LFT: if (eq24) begin
				clr_cnt = 1;
				nxt_state = TRSMT_RGHT;				
			end
			
		// keep shifting for 24 cycles then clear count and validate
		// and go back to prev state.
		// return to idle if out of sync
		TRSMT_RGHT: if (outOfSync)
				nxt_state = IDLE;
			else if (eq24) begin
				clr_cnt = 1;
				vld = 1;
				nxt_state = TRSMT_LFT;
			end
					
	endcase
	
  end
  
  
    
  
  
  
endmodule

`default_nettype wire
