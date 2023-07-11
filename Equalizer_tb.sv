//////////////////////////////
//   POST-SYNTH TESTBENCH   //
//////////////////////////////

`timescale 1ns/1ps
module Equalizer_tb();

import tb_tasks::*;		// import all tasks in tb_tasks

logic clk,RST_n;
logic next_n,prev_n;
logic sht_dwn, Flt_n;
logic [11:0] LP,B1,B2,B3,HP,VOL; // 0 < & < 4095

wire [7:0] LED;
wire ADC_SS_n,ADC_MOSI,ADC_MISO,ADC_SCLK;
wire I2S_data,I2S_ws,I2S_sclk;
wire cmd_n,RX_TX,TX_RX;
wire lft_PDM,rght_PDM;
wire lft_PDM_n,rght_PDM_n;
//logic [15:0] lft_chnnl;

//logic [15:0] lft_amp, rght_amp;
logic peak_found;
logic [15:0] curr_lft;
logic valid;
realtime frequency_left, frequency_right; 
logic [15:0] amplitude_left, amplitude_right;

logic in_range;
logic [15:0] lft_chnnl;
logic [15:0] rght_chnnl;
typedef enum logic {LEFT, RIGHT} LR;

//////////////////////
// Instantiate DUT //
////////////////////
Equalizer iDUT(.clk(clk),.RST_n(RST_n),.LED(LED),.ADC_SS_n(ADC_SS_n),
                .ADC_MOSI(ADC_MOSI),.ADC_SCLK(ADC_SCLK),.ADC_MISO(ADC_MISO),
                .I2S_data(I2S_data),.I2S_ws(I2S_ws),.I2S_sclk(I2S_sclk),.cmd_n(cmd_n),
				.sht_dwn(sht_dwn),.lft_PDM(lft_PDM),.rght_PDM(rght_PDM),
				.lft_PDM_n(lft_PDM_n),.rght_PDM_n(rght_PDM_n),.Flt_n(Flt_n),
				.next_n(next_n),.prev_n(prev_n),.RX(RX_TX),.TX(TX_RX));

//////////////////////////////////////////
// Instantiate model of RN52 BT Module //
////////////////////////////////////////	
RN52 iRN52(.clk(clk),.RST_n(RST_n),.cmd_n(cmd_n),.RX(TX_RX),.TX(RX_TX),.I2S_sclk(I2S_sclk),
           .I2S_data(I2S_data),.I2S_ws(I2S_ws));

//////////////////////////////////////////////
// Instantiate model of A2D and Slide Pots //
////////////////////////////////////////////		   
A2D_with_Pots iPOTs(.clk(clk),.rst_n(RST_n),.SS_n(ADC_SS_n),.SCLK(ADC_SCLK),.MISO(ADC_MISO),
                    .MOSI(ADC_MOSI),.LP(LP),.B1(B1),.B2(B2),.B3(B3),.HP(HP),.VOL(VOL));
			
initial begin
		// Simple test, run the equalizer until its set up, then change the song
		reset(clk, RST_n, Flt_n, next_n, prev_n, peak_found, in_range, LP, HP, B1, B2, B3, VOL);
		updatePots (LP, HP, B1, B2, B3, VOL, .inLP(1028), .inHP(0), .inB1(0), .inB2(0), .inB3(0), .inVol(1000));
		repeat (300000) @(posedge clk); // wait for end of setup
		nextSong(clk, next_n);
		repeat (75000) @(posedge clk);	// wait for song change to percolate thru design
		$stop;
end

always #5 clk = ~ clk;
  
endmodule	  
