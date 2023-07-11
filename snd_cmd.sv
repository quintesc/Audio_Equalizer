module snd_cmd(clk, rst_n, cmd_start, send, cmd_len, RX, TX, resp_rcvd);

	input clk, rst_n;		// clock and active low reset
	input [4:0] cmd_start;	// the start of command
	input send;				// starts sending command when asserted
	input [3:0] cmd_len;	// length of command in bytes
	input RX;				// Received bit
	output TX;				// Transmitted bit
	output resp_rcvd;		// Asserted when the response is received
	
	// UART signals
	logic rx_rdy, clr_rx_rdy;
	logic [7:0] rx_data;
	
	// internal signals
	reg [4:0] addr;
	reg [7:0] tx_data;
	reg [4:0] next_addr;
	
	// SM inputs
	logic last_byte, tx_done /*, send */;
	
	// SM outputs
	logic trmt, inc_addr;

	// instantiate UART and command ROM
	UART uart (.clk(clk) ,.rst_n(rst_n) ,.RX(RX) ,.TX(TX) ,.rx_rdy(rx_rdy) ,.clr_rx_rdy(clr_rx_rdy) 
				,.rx_data(rx_data) ,.trmt(trmt) ,.tx_data(tx_data) ,.tx_done(tx_done));
	cmdROM cmdRom (.clk(clk), .addr(addr), .dout(tx_data));
	
	


	// 2 flipflops to track last_byte
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n) begin
			addr <= 5'b00000;
			next_addr <= 5'b00000;
		end else if (send) begin
			addr <= cmd_start;
			next_addr <= cmd_start + cmd_len;
		end else if (inc_addr)
			addr <= addr + 1;
			
	
	// is 1 when you reach the last byte in a sequence
	assign last_byte = (addr == next_addr);
	
	// is asserted when UART acknowledges the transmission
	assign resp_rcvd = (rx_rdy) && (rx_data == 8'h0A);
	assign clr_rx_rdy = rx_rdy;
	
	
	//// STATE MACHINE ////
	typedef enum reg [1:0] {IDLE, ROM, TRANSMIT, TX_WAIT} state_t;
	state_t state, nxt_state;
	
	
	// keep state transitions at positive clock edges
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n) 
			state <= IDLE;
		else
			state <= nxt_state;
						
	always_comb begin
		// default values
		trmt = 1'b0;
		inc_addr = 1'b0;
		nxt_state = state;
		
		case (state) 
			IDLE:		// wait in Idle until send is asserted
				if (send) 
					nxt_state = ROM;	
			ROM: 		// wait one clock cycle for ROM to access addr
				nxt_state = TRANSMIT;

			TRANSMIT:	// transmit one byte, point to the next
				begin
				trmt = 1'b1;
				inc_addr = 1'b1;
				nxt_state = TX_WAIT;
				end
				
			TX_WAIT: 	// if last byte wait for next send, else keep transmitting
				if (tx_done && !last_byte) 
					nxt_state = TRANSMIT; 
				else if (tx_done)
					nxt_state = IDLE;
		
			default:	// Idle state is the default state
					nxt_state = IDLE;	
				
		endcase
	end


		



endmodule
