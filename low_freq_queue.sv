 module low_freq_queue (clk, rst_n, wrt_smpl, lft_out, rght_out, sequencing, lft_smpl, rght_smpl);

	input clk,rst_n;		// clk and active low reset
	input wrt_smpl;			// start writing a sample and then starting a readout of 1021 samples
	input [15:0] lft_smpl;		// Newest sample from I2S_Serf to be written into queue
	input [15:0] rght_smpl;		// Newest sample from I2S_Serf to be written into queue

	output [15:0] lft_out;		// left sample out
	output [15:0] rght_out;		// right sample out
	output reg sequencing;		// high the whole time the 1021 samples are being read out from the queue
								// signals to FIR that we're sending samples

	// internal signals
	logic [9:0] new_ptr, old_ptr, rd_ptr, end_ptr;  	// size = 1024
	logic full, half_smpl;
	logic wrt_cnt;


	// instantiate left and right ports
	dualPort1024x16 left (.clk, .we(half_smpl), .waddr(new_ptr), .raddr(rd_ptr), .wdata(lft_smpl), .rdata(lft_out));
	dualPort1024x16 right (.clk, .we(half_smpl), .waddr(new_ptr), .raddr(rd_ptr), .wdata(rght_smpl), .rdata(rght_out));
	
	
	////////////////////
	/// Sampling FFs ///
	////////////////////
	// writing on overy other write
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			wrt_cnt <= 0;
		end
		else if (wrt_smpl) 
			wrt_cnt <= wrt_cnt + 1;
		else if ((wrt_cnt == 1) && (wrt_smpl)) //begin
			wrt_cnt <= 0;
	end
	
	// this is the sample toggle
	assign half_smpl = ((wrt_cnt) && (wrt_smpl)) ? 1'b1 : 1'b0;
	
	
	////////////////////
	/// Pointers FFs ///
	////////////////////
	always_ff @ (posedge clk, negedge rst_n) 
		if (!rst_n) begin
			new_ptr <= '0;
			old_ptr <= '0;
			rd_ptr <= '0;
		end
		else if (sequencing)
			rd_ptr <= rd_ptr + 1;
		else if (half_smpl) begin
			new_ptr <= new_ptr + 1;
			if (full) begin
				rd_ptr <= old_ptr;
				old_ptr <= old_ptr + 1;
			end
	end
	
	assign end_ptr = old_ptr + 1020;

	//////////////////////
	/// Full Signal FF ///
	/////////////////////
	always_ff @ (posedge clk, negedge rst_n) 
		if (!rst_n) 
			full <= 1'b0;	
		else if (half_smpl && (new_ptr == 1020)) 	// full if we've written to address 1020
			full <= 1'b1;


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
				if (half_smpl & full) 
					nxt_state = SEQ;	

			SEQ:
				if (rd_ptr == end_ptr) 
					nxt_state = IDLE;
				else 
					sequencing = 1'b1;
			default:
					nxt_state = IDLE;	
				
		endcase
	end
	
endmodule
