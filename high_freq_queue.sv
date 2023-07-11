 module high_freq_queue (clk, rst_n, wrt_smpl, lft_out, rght_out, sequencing, lft_smpl, rght_smpl);

	input clk,rst_n;		// clk and active low reset
	input wrt_smpl;			// start writing a sample and then starting a readout of 1021 samples
	input [15:0] lft_smpl;		// Newest sample from I2S_Serf to be written into queue
	input [15:0] rght_smpl;		// Newest sample from I2S_Serf to be written into queue

	output [15:0] lft_out;		// left sample out
	output [15:0] rght_out;		// right sample out
	output reg sequencing;		// high the whole time the 1021 samples are being read out from the queue

	// internal signals
	logic unsigned [10:0] new_ptr, old_ptr, rd_ptr, end_ptr;
	logic full;
	logic new_ptr_1535, old_ptr_1535, rd_ptr_1535;
	
	// instantiate left and right ports
	dualPort1536x16 left (.clk, .we(wrt_smpl), .waddr(new_ptr), .raddr(rd_ptr), .wdata(lft_smpl), .rdata(lft_out));
	dualPort1536x16 right (.clk, .we(wrt_smpl), .waddr(new_ptr), .raddr(rd_ptr), .wdata(rght_smpl), .rdata(rght_out));
	
	////////////////////
	/// Pointers FFs ///
	////////////////////
	always_ff @ (posedge clk, negedge rst_n) 
		if (!rst_n) begin
			new_ptr <= '0;
			old_ptr <= '0;
			rd_ptr <= '0;  // new
		end
		else if (sequencing)
			rd_ptr <= (rd_ptr_1535) ? '0 : rd_ptr + 1;		// new
		else if (wrt_smpl && !full) begin
			new_ptr <= (new_ptr_1535) ? '0 : new_ptr + 1;

		end else if (wrt_smpl && full) begin
			rd_ptr <= old_ptr;		
			old_ptr <= (old_ptr_1535) ? '0 : old_ptr + 1;
			new_ptr <= (new_ptr_1535) ? '0 : new_ptr + 1;
	end
	
	
	/*always_ff @ (posedge clk, negedge rst_n) 
		if (!rst_n)
			rd_ptr <= '0;
		else if (sequencing)
			rd_ptr <= (rd_ptr_1535) ? '0 : rd_ptr + 1; */
	

	//////////////////////
	/// Full Signal FF ///
	/////////////////////
	always_ff @ (posedge clk, negedge rst_n) 
		if (!rst_n) 
			full <= 1'b0;	
		else if (wrt_smpl && (new_ptr == 1530))
			full <= 1'b1;
		

	// Helper signals
	assign new_ptr_1535 = (new_ptr == 1535);
	assign old_ptr_1535 = (old_ptr == 1535);
	assign rd_ptr_1535 = (rd_ptr == 1535);
	assign end_ptr = (old_ptr < 516) ? (old_ptr + 1020) : (old_ptr- 516);


	//// STATE MACHINE ////
	typedef enum reg {IDLE, SEQ} state_t;
	state_t state, nxt_state;	
	
	
	// keep state transitions at positive clock edges
	always_ff @ (posedge clk, negedge rst_n)
		if (!rst_n) 
			state <= IDLE;
		else
			state <= nxt_state;
			
		always_comb begin
		// default values
		sequencing = 1'b0;
		nxt_state = state;
		
		case (state) 
			IDLE:
				if (wrt_smpl & full) 
					nxt_state = SEQ;	

			SEQ: begin
			   	sequencing = 1'b1;
				if (rd_ptr === end_ptr) 
					nxt_state = IDLE;
			end
			default:
					nxt_state = IDLE;	
				
		endcase
	end
	
endmodule
