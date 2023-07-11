package tb_tasks;

	typedef enum logic {LEFT, RIGHT} LR;
	typedef enum logic [2:0] {LP_pot, B1_pot, B2_pot, B3_pot, HP_pot} POT;
	logic zero_found_R;
	logic zero_found_L;
	logic sus_zero_L;
	logic sus_zero_R;
  	///////////////////////////
	//     Reset Values      //
	///////////////////////////
  	task automatic reset(ref clk, RST_n, Flt_n, next_n, prev_n, peak_found, in_range, ref [11:0] LP, HP, B1, B2, B3, VOL);
	
		clk = 0;
		RST_n = 0;
		
		@(posedge clk);
		@(negedge clk);
		
		RST_n = 1;
		Flt_n = 1;
		next_n = 1'b1;
		prev_n = 1'b1;
		LP = 0;
		HP = 0;
		B1 = 0;
		B2 = 0;
		B3 = 0;
		VOL = 0;
		peak_found = 0;
		in_range = 0;
		
	endtask : reset
	
	
  	///////////////////////////
	//     Update inputs     //
	///////////////////////////
	task automatic updatePots (ref logic [11:0] LP, HP, B1, B2, B3, VOL, input logic [11:0] inLP, inHP, inB1, inB2, inB3, inVol);

		LP = inLP;
		HP = inHP;
		B1 = inB1;
		B2 = inB2;
		B3 = inB3;
		VOL = inVol;	

	endtask : updatePots
	
	
	///////////////////////////
	//       Next Song       //
	///////////////////////////
	task automatic nextSong(ref clk, next_n);
	
		next_n = 1'b0;
		@ (negedge clk);
		@ (negedge clk);
		next_n = 1'b1;
		
	endtask : nextSong
	
	
	///////////////////////////
	//     Previous Song     //
	///////////////////////////
	task automatic prevSong(ref clk, prev_n);
	
		prev_n = 1'b0;
		@ (negedge clk);
		@ (negedge clk);
		prev_n = 1'b1;
		
	endtask : prevSong


	


	

	


endpackage
