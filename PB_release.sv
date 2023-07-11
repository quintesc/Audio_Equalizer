module PB_release (clk, PB, rst_n, released);

	input clk;
	input PB;
	input rst_n;
	output released;
	
	reg q1, q2, q3;
	
	// flipflops
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n) begin
			q1 <= 1'b1;
			q2 <= 1'b1;
			q3 <= 1'b1;
		end else begin
			q3 <= q2;
			q2 <= q1;
			q1 <= PB;
		end
	end
	
	assign released = (!q3) & q2;

	
	
	
endmodule