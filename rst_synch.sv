module rst_synch (clk, rst_n, RST_n);

	input clk;
	input RST_n;
	output reg rst_n;
	
	reg rst_sync;
	
	// First flipflop
	always_ff @(negedge clk, negedge RST_n) begin
		if (!RST_n) 
			rst_sync <= 1'b0;
		else 
			rst_sync <= 1'b1;
	end
	
	// Second flipflop
	always_ff @(negedge clk, negedge RST_n) begin
		if (!RST_n) 
			rst_n <= rst_sync;
		else 
			rst_n <= rst_sync;
	end
	

endmodule