`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Designed and Tested for MT25QU256
// Dual I/O and Quand I/O modes are not supported
// Extended Mode with Quad Output Fast Read and Quad Input Fast Program are supported
//////////////////////////////////////////////////////////////////////////////////
module spi_phy
(
    input                   clk,             	// Clock signal
    input                   rst,            	// Active-high, synchronous reset
    input                   load_in,            // Active-high, synchronous load
    output                  load_full,            // Active-high, synchronous full
	input	[7:0]           command_len_in,		// command length at SPI output width
	input	[7:0]           addr_len_in,		// addr length at SPI output width
	input   [7:0]			dummy_len_in,		// dummy cycles
	input	[15:0]          data_len_in,        // data length at SPI output width
	input	[31:0]          command_in,
	input	[63:0]          addr_in,
	input	[63:0]          data_in,
    input                   tristate_in,        //1'b1 for flash to fpga, 1'b0 for fpga to flash
	output reg              busy,
	output reg				SCLK,
	output reg              CS,
	output reg	[3:0]     	DOUT,
    output reg  [3:0]       DTS,
	input	[3:0]	        DIN,
	output	[63:0]			fetch_dout,
	input					fetch_in,
	output					fetch_empty
);

wire		load_begin, load_end;
reg			load_in_reg;
reg	 [8:0]	command_len_cnt;
wire [8:0]  command_idx;
reg	 [8:0]	addr_len_cnt;
wire [8:0]  addr_idx;
reg	 [8:0]	dummy_len_cnt;
reg	 [16:0]	data_len_cnt;
reg  [31:0]	command_reg;
reg  [63:0]	addr_reg;
reg         tristate_in_reg;
wire [63:0]	fifo_out;
reg  [63:0]	fifo_reg;
reg  [15:0] fifo_demux_cnt;
wire        fifo_rden_1st;
reg			fifo_rden_1st_reg;
wire        fifo_rden_rest;
reg			fifo_rden_rest_reg;
reg  [63:0]	din_reg;
reg  [15:0]	din_reg_cnt;
reg         din_wr_last_pre_reg;
reg         din_wr_last_reg;
reg         din_wr_reg;

always@(posedge clk)
begin
	if(rst)
	begin
		load_in_reg = 0;
	end
/*	else
	begin
		load_in_reg = load_in;
	end     */
    else if(load_in)
    begin
        load_in_reg = 1;
    end
    else if(~load_in && ~SCLK)
    begin
        load_in_reg = 0;
    end
end


assign load_begin = (load_in ^ load_in_reg) & load_in;
//assign load_end = (load_in ^ load_in_reg) & load_in_reg;

always@(posedge clk)
begin
	if(rst)
	begin
		command_len_cnt = 0;
		addr_len_cnt = 0;
		dummy_len_cnt = 0;
		data_len_cnt = 0;
	end
	else if(load_begin)
	begin
		command_len_cnt[8:1] = command_len_in;
		addr_len_cnt[8:1] = addr_len_in;
		dummy_len_cnt[8:1] = dummy_len_in;
		data_len_cnt[16:1] = data_len_in;
	end
	else if(load_in_reg)
	begin
		command_len_cnt = command_len_cnt;
		addr_len_cnt = addr_len_cnt;
		dummy_len_cnt = dummy_len_cnt;
		data_len_cnt = data_len_cnt;
	end
	else if(|command_len_cnt)
	begin
		command_len_cnt = command_len_cnt - 1;
	end
	else if(|addr_len_cnt && ~|command_len_cnt)
	begin
		addr_len_cnt = addr_len_cnt - 1;
	end
	else if(|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		dummy_len_cnt = dummy_len_cnt - 1;
	end
	else if(|data_len_cnt && ~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		data_len_cnt = data_len_cnt - 1;
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
		command_reg = 0;
		addr_reg = 0;
	end
	else if(load_begin)
	begin
		command_reg = command_in;
		addr_reg = addr_in;
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
		busy = 0;
	end
	else if(load_begin)
	begin
		busy = 1;
	end
	else if(~|data_len_cnt && ~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		busy = 0;
	end
end

fifo_generator_0 fifo_generator_inst (
  .clk(clk),                  // input wire clk
  .srst(rst),                // input wire srst
  .din(data_in),                  // input wire [63 : 0] din
  .wr_en(load_in),              // input wire wr_en
  .rd_en(fifo_rden_1st | fifo_rden_rest),              // input wire rd_en
  .dout(fifo_out),                // output wire [63 : 0] dout
  .full(load_full),                // output wire full
  .empty(),              // output wire empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);

always@(posedge clk)
begin
	if(rst)
	begin
		CS = 1;
	end
	else if(load_in_reg)
	begin
	   CS = 1;
    end
	else if(|data_len_cnt || |dummy_len_cnt || |addr_len_cnt || |command_len_cnt)
	begin
		CS = 0;
	end
	else
	begin
		CS = 1;
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
		SCLK = 0;
	end
    else
    begin
        SCLK = ~SCLK;
    end
end

assign command_idx = |command_len_cnt ? command_len_cnt - 1 : 0;
assign addr_idx = |addr_len_cnt ? addr_len_cnt - 1 : 0;

always@(posedge clk)
begin
	if(rst)
	begin
		DOUT = 0;
	end
	else if(|command_len_cnt)
	begin
		DOUT[0] = command_reg[command_idx[8:1]];
		DOUT[3:1] = 0;
	end
	else if(|addr_len_cnt && ~|command_len_cnt)
	begin
		DOUT[0] = addr_reg[addr_idx[8:1]];
		DOUT[3:1] = 0;
	end 
	else if(|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		DOUT = 0;
	end
//	else if(fifo_rden_1st_reg)
	else if(fifo_rden_1st_reg | fifo_rden_rest_reg)
	begin
		DOUT = fifo_out[63:60];
	end 
//	else if(|data_len_cnt)
	else if(|data_len_cnt[8:1] && ~data_len_cnt[0])
	begin
		DOUT = fifo_reg[63:60];
	end 
end

always@(posedge clk)
begin
	if(rst)
	begin
		DTS = 4'hF;
	end
	else if(load_begin)
	begin
		DTS = 4'hE;
    end
	else if(~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt && ~tristate_in_reg)
	begin
		DTS = 4'h0;
	end
	else if(~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt && tristate_in_reg)
	begin
		DTS = 4'hF;
	end
	else if(~|data_len_cnt &&  ~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		DTS = 4'hF;
	end
end

always@(posedge clk)
begin
    if(rst)
    begin
        tristate_in_reg = 1;
    end
    else if(load_begin)
    begin
        tristate_in_reg = tristate_in;
    end
end
        

always@(posedge clk)
begin
	if(rst)
	begin
		fifo_demux_cnt = 0;
	end
	else if(~busy)
	begin
		fifo_demux_cnt = 0;
	end
	else if(|fifo_demux_cnt)
	begin
		fifo_demux_cnt = fifo_demux_cnt + 1;
	end
	else if(|data_len_cnt && (dummy_len_cnt[0]|addr_len_cnt[0]|command_len_cnt[0]) && ~|dummy_len_cnt[8:1] && ~|addr_len_cnt[8:1] && ~|command_len_cnt[8:1])
	begin
		fifo_demux_cnt = fifo_demux_cnt + 1;
	end
end

assign fifo_rden_1st = (dummy_len_cnt[0]|addr_len_cnt[0]|command_len_cnt[0]) && ~|dummy_len_cnt[8:1] && ~|addr_len_cnt[8:1] && ~|command_len_cnt[8:1];
assign fifo_rden_rest = |fifo_demux_cnt[15:5] & (~|fifo_demux_cnt[4:0]);

always@(posedge clk)
begin
	if(rst)
	begin
		fifo_rden_1st_reg = 0;
		fifo_rden_rest_reg = 0;
	end
	else
	begin
		fifo_rden_1st_reg = fifo_rden_1st;
		fifo_rden_rest_reg = fifo_rden_rest;
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
		fifo_reg = 0;
	end
	else if(fifo_rden_1st_reg | fifo_rden_rest_reg)
	begin
		fifo_reg = fifo_out;
	end 
	else if(|fifo_demux_cnt[15:1] && fifo_demux_cnt[0] == 1'b0)
	begin
		fifo_reg = fifo_reg << 4;
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
		din_reg_cnt = 0;
		din_reg = 0;
	end
    else if(load_begin)
    begin
		din_reg_cnt = 0;
		din_reg = 0;
    end
	else if(data_len_cnt[0] && ~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		din_reg_cnt = din_reg_cnt + 1;
		din_reg = {din_reg[59:0], DIN};
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
		din_wr_last_pre_reg = 0;
	end
	else if(load_begin)
	begin
		din_wr_last_pre_reg = 0;
	end
	else if(~|data_len_cnt && ~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		din_wr_last_pre_reg = 1;
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
		din_wr_last_reg = 0;
	end
	else if(~|data_len_cnt && ~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt && ~din_wr_last_pre_reg)
	begin
		din_wr_last_reg = 1;
	end
	else
	begin
		din_wr_last_reg = 0;
	end
end

always@(posedge clk)
begin
	if(rst)
	begin
	   din_wr_reg = 0;
	end
	else if(~|data_len_cnt && ~|dummy_len_cnt && ~|addr_len_cnt && ~|command_len_cnt)
	begin
		din_wr_reg = 0;
	end
	else if(|din_reg_cnt[15:4] && ~|din_reg_cnt[3:0] && ~din_wr_reg)
	begin
	   din_wr_reg = 1;
	end
	else
	begin
		din_wr_reg = 0;
	end
end

fifo_generator_0 fifo_generator_rd_inst (
  .clk(clk),                  // input wire clk
  .srst(rst),                // input wire srst
  .din(din_reg),                  // input wire [63 : 0] din
  .wr_en(din_wr_reg | din_wr_last_reg),              // input wire wr_en
  .rd_en(fetch_in),              // input wire rd_en
  .dout(fetch_dout),                // output wire [63 : 0] dout
  .full(),                // output wire full
  .empty(fetch_empty),              // output wire empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);
endmodule