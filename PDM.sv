module PDM (clk, rst_n, duty, PDM, PDM_n);

	input clk;								// 50MHz system clk
	input rst_n;							// Asynch active low reset
	input wire unsigned [15:0] duty;		// Specifies duty cycle (unsigned 16-bit)
	output reg PDM;							// PDM signals
	output reg PDM_n;						// Preset
	
	reg [15:0] duty_reg;
	logic AgtB;
	logic [15:0] muxOut; 
	logic [15:0] subOut; 
	logic [15:0] addOut;
	reg [15:0] addOut_reg; 	
	
	// Flip flop for the duty cycle
	always_ff @(posedge clk, negedge rst_n) begin
	
		if(!rst_n) 
			duty_reg <= 16'h0000;
		else
			duty_reg <= duty;
			
	end
	
	// Flip flop for the output of the adder
	always_ff @(posedge clk, negedge rst_n) begin
	
		if(!rst_n) 
			addOut_reg <= 16'h0000;
		else
			addOut_reg <= addOut;
			
	end
	
	// Combinational logic
	always_comb begin
		muxOut = (AgtB) ? 16'hFFFF : 16'h0000;
		subOut = muxOut - duty_reg;
		addOut = addOut_reg + subOut;
	end
	
	assign  AgtB = (duty_reg >= addOut_reg) ? 1'b1: 1'b0;

	// Flip flop for PDM
	always_ff @(posedge clk, negedge rst_n) begin
	
		if(!rst_n) 
			PDM <= 1'b0;
		else
			PDM <= AgtB;
			
	end
	
	// Flip flop for PDM_n
	always_ff @(posedge clk, negedge rst_n) begin
	
		if(!rst_n) 
			PDM_n <= 1'b1;
		else
			PDM_n <= ~AgtB;
			
	end
	
	
	
endmodule