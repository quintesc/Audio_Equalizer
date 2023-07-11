module EQ_engine (clk, rst_n, 
				  VOLUME, POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, 
				  aud_in_lft ,aud_out_lft,
			      aud_in_rht ,aud_out_rht,
			      vld ,seq_low);
				  
    input clk;			// 50MHz CLOCK
	input rst_n;		// unsynched active low reset from push button
	input [11:0] POT_LP, POT_B1, POT_B2, POT_B3, POT_HP, VOLUME; // slider inputs
	input signed [15:0] aud_in_lft, aud_in_rht;
	input vld;
	output seq_low; // TODO: What do I do with this???????????????????????
	output signed [15:0] aud_out_lft, aud_out_rht;
	
	
	// Internal signals for queue
	logic [15:0] lft_out_high_q, lft_out_low_q;		// left sample out
	logic [15:0] rght_out_high_q, rght_out_low_q;	// right sample out
	logic sequencing_high_q, sequencing_low_q;		// high the whole time the 1021 samples are being read out from the queue
	
	
	// Internal signals for filters
	logic [15:0] lft_filtered_LP, rght_filtered_LP;
	logic [15:0] lft_filtered_B1, rght_filtered_B1;
	logic [15:0] lft_filtered_B2, rght_filtered_B2;
	logic [15:0] lft_filtered_B3, rght_filtered_B3;
	logic [15:0] lft_filtered_HP, rght_filtered_HP;
	
	// Internal signals for band scales
	logic signed [15:0] lft_scaled_LP, rght_scaled_LP;
	logic signed [15:0] lft_scaled_B1, rght_scaled_B1;
	logic signed [15:0] lft_scaled_B2, rght_scaled_B2;
	logic signed [15:0] lft_scaled_B3, rght_scaled_B3;
	logic signed [15:0] lft_scaled_HP, rght_scaled_HP;
	
	// Internal signals for arithmateics
	logic signed [16:0] sum_aud_lft, sum_aud_rght; // TODO: should be one bit more?
	logic signed [28:0] final_aud_lft, final_aud_rght;
	
	
	///////////////////////////////////////
	// Instantiate Left & Right Queues	//
	/////////////////////////////////////

	high_freq_queue highFreqQueue (.clk(clk), .rst_n(rst_n), .wrt_smpl(vld) ,.lft_smpl(aud_in_lft), .rght_smpl(aud_in_rht), 
									.lft_out(lft_out_high_q), .rght_out(rght_out_high_q), .sequencing(sequencing_high_q));
									
	low_freq_queue lowFreqQueue (.clk(clk), .rst_n(rst_n), .wrt_smpl(vld), .lft_smpl(aud_in_lft), .rght_smpl(aud_in_rht), 
									.lft_out(lft_out_low_q), .rght_out(rght_out_low_q), .sequencing(sequencing_low_q));
	
	
	/////////////////////////////////////////////
	// Instantiate FIR Filters Low Freq Queue //
	///////////////////////////////////////////
	
			//// LP ////
			FIR_LP LP (.clk(clk), .rst_n(rst_n), .sequencing(sequencing_low_q),
						.lft_in(lft_out_low_q), .rght_in(rght_out_low_q),
						.lft_out(lft_filtered_LP), .rght_out(rght_filtered_LP));
			
			//// B1 ////
			FIR_B1 B1 (.clk(clk), .rst_n(rst_n), .sequencing(sequencing_low_q),
						.lft_in(lft_out_low_q), .rght_in(rght_out_low_q),
						.lft_out(lft_filtered_B1), .rght_out(rght_filtered_B1));
				  
	//////////////////////////////////////////////
	// Instantiate FIR Filters High Freq Queue //
	////////////////////////////////////////////
	
			//// B2 ////
			
			FIR_B2 B2 (.clk(clk), .rst_n(rst_n), .sequencing(sequencing_high_q),
						.lft_in(lft_out_high_q), .rght_in(rght_out_high_q),
						.lft_out(lft_filtered_B2), .rght_out(rght_filtered_B2));
							
			
			//// B3 ////
			FIR_B3 B3 (.clk(clk), .rst_n(rst_n), .sequencing(sequencing_high_q),
						.lft_in(lft_out_high_q), .rght_in(rght_out_high_q),
						.lft_out(lft_filtered_B3), .rght_out(rght_filtered_B3));


			//// HP ////
			FIR_HP HP (.clk(clk), .rst_n(rst_n), .sequencing(sequencing_high_q),
						.lft_in(lft_out_high_q), .rght_in(rght_out_high_q),
						.lft_out(lft_filtered_HP), .rght_out(rght_filtered_HP));
	
	/////////////////////////////////////
	// Instantiate Right Band Scales  //
	///////////////////////////////////

	band_scale LP_rght (.POT(POT_LP), .audio(rght_filtered_LP), .scaled(rght_scaled_LP), .clk(clk), .rst_n(rst_n));
	band_scale B1_rght (.POT(POT_B1), .audio(rght_filtered_B1), .scaled(rght_scaled_B1), .clk(clk), .rst_n(rst_n));
	band_scale B2_rght (.POT(POT_B2), .audio(rght_filtered_B2), .scaled(rght_scaled_B2), .clk(clk), .rst_n(rst_n));
	band_scale B3_rght (.POT(POT_B3), .audio(rght_filtered_B3), .scaled(rght_scaled_B3), .clk(clk), .rst_n(rst_n));
	band_scale HP_rght (.POT(POT_HP), .audio(rght_filtered_HP), .scaled(rght_scaled_HP), .clk(clk), .rst_n(rst_n));	
			
	/////////////////////////////////////
	// Instantiate Left Band Scales   //
	///////////////////////////////////
	
	band_scale LP_lft (.POT(POT_LP), .audio(lft_filtered_LP), .scaled(lft_scaled_LP), .clk(clk), .rst_n(rst_n));
	band_scale B1_lft (.POT(POT_B1), .audio(lft_filtered_B1), .scaled(lft_scaled_B1), .clk(clk), .rst_n(rst_n));
	band_scale B2_lft (.POT(POT_B2), .audio(lft_filtered_B2), .scaled(lft_scaled_B2), .clk(clk), .rst_n(rst_n));
	band_scale B3_lft (.POT(POT_B3), .audio(lft_filtered_B3), .scaled(lft_scaled_B3), .clk(clk), .rst_n(rst_n));
	band_scale HP_lft (.POT(POT_HP), .audio(lft_filtered_HP), .scaled(lft_scaled_HP), .clk(clk), .rst_n(rst_n));	
	
	/////////////////////////////////////////
	// Flop audio sum for pipelining	  //
	///////////////////////////////////////
	always @(posedge clk, negedge rst_n) 
		if(!rst_n)
			sum_aud_rght <= '0;
		else
			sum_aud_rght <= rght_scaled_LP + rght_scaled_B1 + rght_scaled_B2 + rght_scaled_B3 + rght_scaled_HP;
	
	always @(posedge clk, negedge rst_n) 
		if(!rst_n)
			sum_aud_lft <= '0;
		else
			sum_aud_lft <= lft_scaled_LP + lft_scaled_B1 + lft_scaled_B2 + lft_scaled_B3 + lft_scaled_HP;
	
	
	assign final_aud_rght = signed'({1'b0, VOLUME}) * signed'(sum_aud_rght);
	assign final_aud_lft = signed'({1'b0, VOLUME}) * signed'(sum_aud_lft);

	assign aud_out_rht = final_aud_rght [27:12];
	assign aud_out_lft = final_aud_lft [27:12];


endmodule
