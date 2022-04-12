`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Designed and Tested for MT25QU256
// Dual I/O and Quand I/O modes are not supported
// Extended Mode with Quad Output Fast Read and Quad Input Fast Program are supported
//////////////////////////////////////////////////////////////////////////////////
module button_debounce
(
    input                   clk,             	// Clock signal
    input                   rst,            	// Active-high, synchronous reset
    input  [4:0]            button_in,
	output [4:0]            button_out
);

reg	[4:0]	button_in_reg;

assign button_out[0] = (button_in[0] ^ button_in_reg[0]) & button_in_reg[0];
assign button_out[1] = (button_in[1] ^ button_in_reg[1]) & button_in_reg[1];
assign button_out[2] = (button_in[2] ^ button_in_reg[2]) & button_in_reg[2];
assign button_out[3] = (button_in[3] ^ button_in_reg[3]) & button_in_reg[3];
assign button_out[4] = (button_in[4] ^ button_in_reg[4]) & button_in_reg[4];


always@(posedge clk)
begin
	if(rst)
	begin
		button_in_reg = 0;
	end
	else
	begin
		button_in_reg = button_in;
	end
end
endmodule 