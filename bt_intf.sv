module bt_intf(clk, rst_n, next_n, prev_n, cmd_n, TX, RX);

	input clk, rst_n;
	input prev_n, next_n;
	input RX;
	
	output TX;
	output logic cmd_n;
	
	
	logic next, prev;
	logic send, resp_rcvd;
	logic full;
	logic [16:0] cntr;
	logic [4:0] cmd_start;
	logic [3:0] cmd_len;


	snd_cmd snd0 (.clk, .rst_n, .cmd_start(cmd_start) , .send(send) ,
				.cmd_len(cmd_len) , .RX(RX) , .TX(TX) , .resp_rcvd(resp_rcvd));
				
	PB_release PB0 (.clk, .PB(next_n), .rst_n, .released(next));
	PB_release PB1 (.clk, .PB(prev_n), .rst_n, .released(prev));


	always_ff @ (posedge clk, negedge rst_n) 
		if (!rst_n) 
			cntr <= 0;
		else
			cntr <= (~(~(~(~(~(~(~(~(~(~(~(~(~(~cntr)))))))))))))) + 1;
			
	assign full = (cntr == '1);
	
	
	typedef enum reg [2:0] {WAIT, RESP_1, RESP_2, RESP_3, PB} state_t;
	state_t state, nxt_state;
	
	
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n) 
			state <= WAIT;
		else
			state <= nxt_state;
						
	always_comb begin
		// default values
		send = 0;
		cmd_start = 0;
		cmd_len = 0;	
		cmd_n = 0;
		nxt_state = state;
		
		case (state) 
			WAIT:		
				if (full) begin 
					cmd_n = 0;
					nxt_state = RESP_1;
				end else 
					cmd_n = 1;
			RESP_1:
				if (resp_rcvd) begin
					send = 1;
					cmd_len = 6;
					cmd_start = 0;
					nxt_state = RESP_2;
				end
			RESP_2:	
				if (resp_rcvd) begin
					send = 1;
					cmd_len = 10;
					cmd_start = 6;
					nxt_state = RESP_3;
				end
				
			RESP_3:	
				if (resp_rcvd)
					nxt_state = PB;
					
			PB:	
				if (next) begin
					send = 1;
					cmd_len = 4;
					cmd_start = 16;
					nxt_state = RESP_3;
				end 
				else if (prev) begin
					send = 1;
					cmd_len = 4;
					cmd_start = 20;
					nxt_state = RESP_3;
				end
		
			default:	// Idle state is the default state
					nxt_state = WAIT;	
				
		endcase
		
	end

endmodule
