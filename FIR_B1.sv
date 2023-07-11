`default_nettype none
module FIR_B1(output logic[15:0] lft_out,
	      output logic [15:0] rght_out,
	      input wire [15:0] lft_in, input wire [15:0] rght_in,
			input wire clk, input wire rst_n, input wire sequencing);


logic [9:0] addr;
logic rst_addr, inc_addr, rst_accum, accum;
logic signed [31:0] rght_in_signed, lft_in_signed;
logic [31:0] rght_out_ff, lft_out_ff;
logic signed [15:0] coeff;

// instantiating ROM to get coeffs
ROM_B1 B1(.clk(clk), .addr(addr), .dout(coeff));

assign rght_in_signed = signed'(rght_in) * coeff;
assign lft_in_signed = signed'(lft_in) * coeff;

// address flop
always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n)
		addr <= 0;
	else if (rst_addr)
		addr <= 0;
	else if (inc_addr)
		addr <= addr + 1;
end

// accum
assign rght_out = rght_out_ff[30:15];
assign lft_out = lft_out_ff[30:15];

always_ff @(posedge clk, negedge rst_n) begin
	if (!rst_n) begin
		lft_out_ff <= '0;
		rght_out_ff <= '0;
	end
	else if (rst_accum) begin
		lft_out_ff <= '0;
		rght_out_ff <= '0;
	end
	else if (accum) begin
		lft_out_ff <= lft_in_signed + lft_out_ff;
		rght_out_ff <= rght_in_signed + rght_out_ff;
	end
end


typedef enum reg [1:0] {IDLE, MAC} state_t; // MAC = multiply accumulate
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
        if(!rst_n)
            state <= IDLE;
        else 
            state <= nxt_state;
    end

// state machine
always_comb begin
	rst_addr = 1'b0;
	inc_addr = 1'b0;
	rst_accum = 1'b0;
	accum = 1'b0;
	nxt_state = state;
	
	case(state)
		IDLE : begin
		    rst_addr = 1'b1;
			if(sequencing) begin
				rst_accum = 1'b1;
				nxt_state = MAC;
			end				
		end
		MAC: begin
			if(sequencing) begin
				accum = 1'b1;
				inc_addr = 1'b1;
			end else
				nxt_state = IDLE;
		end
	endcase
end // always_comb
			

endmodule
`default_nettype wire