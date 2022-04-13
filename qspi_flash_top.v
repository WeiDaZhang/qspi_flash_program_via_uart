`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06.04.2022 14:49:11
// Design Name: 
// Module Name: qspi_flash_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module qspi_flash_top
(
    input [4:0]  BUTTON_IN,
    input        UART_RX,
    output       UART_TX,
    output       LED

);

wire            clk;
wire            EOS;
wire    [3:0]   DI;
wire    [3:0]   DO;
wire    [3:0]   DTS;
wire            FCSBO;
wire            USRCCLKO;

reg             rst;
reg     [28:0]  one_shot_cnt;
reg             one_shot;
reg     [24:0]  led_cnt;

wire    [4:0]   button_out;

wire            spi_load;
wire            spi_load_full;
wire    [7:0]   spi_command_len;
wire    [7:0]   spi_addr_len;
wire    [7:0]   spi_dummy_len;
wire    [15:0]  spi_data_len;
wire    [31:0]  spi_command;
wire    [63:0]  spi_addr;
wire    [63:0]  spi_data;
wire            spi_tristate;
wire            spi_busy;
wire    [63:0]  spi_fetch_dout;
wire            spi_fetch;
wire            spi_fetch_empty;

wire            tx_dv;
wire    [7:0]   tx_byte;
wire            tx_active;
wire            tx_done;
wire            rx_dv;
wire    [7:0]   rx_byte;

wire    [3:0]   macro_states;
wire            macro_states_valid;
wire            uart_macro_states_done;
wire            flash_macro_states_done;
wire    [31:0]  rx_num;
wire    [15:0]  rx_cnt;

wire    [31:0]  start_addr;
wire            buff_rden;
wire    [63:0]  buff_data;
wire            buff_wren;
wire            buff_prog_empty;
wire            buff_empty;
wire            buff_full;


spi_phy spi_phy_inst
(
    .clk(clk),                 //input                   clk,                 // Clock signal
    .rst(rst),                 //input                   rst,                // Active-high, synchronous reset
    .load_in(spi_load),             //input                   load_in,            // Active-high, synchronous load
    .load_full(spi_load_full),           //output                  load_full,            // Active-high, synchronous full
    .command_len_in(spi_command_len),      //input    [7:0]           command_len_in,        // command length at SPI output width
    .addr_len_in(spi_addr_len),         //input    [7:0]           addr_len_in,        // addr length at SPI output width
    .dummy_len_in(spi_dummy_len),        //input   [7:0]            dummy_len_in,        // dummy cycles
    .data_len_in(spi_data_len),         //input    [15:0]          data_len_in,        // data length at SPI output width
    .command_in(spi_command),          //input    [31:0]          command_in,
    .addr_in(spi_addr),             //input    [63:0]          addr_in,
    .data_in(spi_data),             //input    [63:0]          data_in,
    .tristate_in(spi_tristate),         //input                   tristate_in,        //1'b1 for flash to fpga, 1'b0 for fpga to flash
    .busy(spi_busy),                //output reg              busy,
    .SCLK(USRCCLKO),                //output reg                SCLK,
    .CS(FCSBO),                  //output reg              CS,
    .DOUT(DO),                //output reg    [3:0]         DOUT,
    .DTS(DTS),                 //output reg  [3:0]       DTS,
    .DIN(DI),                 //input    [3:0]            DIN,
    .fetch_dout(spi_fetch_dout),          //output    [63:0]            fetch_dout,
    .fetch_in(spi_fetch),            //input                    fetch_in,
    .fetch_empty(spi_fetch_empty)         //output                    fetch_empty
);

flash_state_machine flash_state_machine_inst
(
    .clk(clk),            //input                   clk,                 // Clock signal
    .rst(rst),            //input                   rst,                // Active-high, synchronous reset
    .macro_states(macro_states),                //input  [3:0]            macro_states,
    .macro_states_valid(macro_states_valid),      //input                   macro_states_valid,
    .macro_states_done(flash_macro_states_done),       //output reg              macro_states_done,
    .addr_in(),//start_addr),     //input  [63:0]           addr_in,
    .data_in(),//buff_data),     //input  [63:0]           data_in,
    .buff_rden(buff_rden),   //output reg              buff_rden,
    .load_out(spi_load),            //output reg              load_out,            // Active-high, synchronous load
    .load_full_in(spi_load_full),            //input                   load_full_in,            // Active-high, synchronous full
    .command_len_out(spi_command_len),            //output reg [7:0]        command_len_out,        // command length at SPI output width
    .addr_len_out(spi_addr_len),            //output reg [7:0]        addr_len_out,        // addr length at SPI output width
    .dummy_len_out(spi_dummy_len),            //output reg [7:0]        dummy_len_out,        // dummy cycles
    .data_len_out(spi_data_len),            //output reg [15:0]       data_len_out,        // data length at SPI output width
    .command_out(spi_command),            //output reg [31:0]       command_out,
    .addr_out(),//spi_addr),            //output reg [63:0]       addr_out,
    .data_out(),//spi_data),            //output reg [63:0]       data_out,
    .tristate_out(spi_tristate),            //output reg              tristate_out,        //1'b1 for flash to fpga, 1'b0 for fpga to flash
    .spi_busy_in(spi_busy),            //input                   busy,
    .fetch_din(spi_fetch_dout),            //input    [63:0]            fetch_din,
    .fetch_out(spi_fetch),            //output reg                 fetch_out,
    .fetch_empty_in(spi_fetch_empty)             //input                    fetch_empty_in
);


button_debounce button_debounce_inst
(
    .clk(clk),            //input                   clk,                 // Clock signal
    .rst(rst),             //input                   rst,                // Active-high, synchronous reset
    .button_in(BUTTON_IN),       //input  [4:0]            button_in,
    .button_out(button_out)       //output [4:0]            button_out
);


STARTUPE3
#(
    .PROG_USR("FALSE"),  // Activate program event security feature. Requires encrypted bitstreams.
    .SIM_CCLK_FREQ(0.0)  // Set the Configuration Clock Frequency (ns) for simulation.
)
 STARTUPE3_inst
(
    .CFGCLK(),       // 1-bit output: Configuration main clock output.
    .CFGMCLK(clk),     // 1-bit output: Configuration internal oscillator clock output.
    .DI(DI),               // 4-bit output: Allow receiving on the D input pin.
    .EOS(EOS),             // 1-bit output: Active-High output signal indicating the End Of Startup.
    .PREQ(PREQ),           // 1-bit output: PROGRAM request to fabric output.
    .DO(DO),               // 4-bit input: Allows control of the D pin output.
    .DTS(DTS),             // 4-bit input: Allows tristate of the D pin.
    .FCSBO(FCSBO),         // 1-bit input: Controls the FCS_B pin for flash access.
    .FCSBTS(0),       // 1-bit input: Tristate the FCS_B pin.
    .GSR(GSR),             // 1-bit input: Global Set/Reset input (GSR cannot be used for the port).
    .GTS(GTS),             // 1-bit input: Global 3-state input (GTS cannot be used for the port name).
    .KEYCLEARB(KEYCLEARB), // 1-bit input: Clear AES Decrypter Key input from Battery-Backed RAM (BBRAM).
    .PACK(PACK),           // 1-bit input: PROGRAM acknowledge input.
    .USRCCLKO(USRCCLKO),   // 1-bit input: User CCLK input.
    .USRCCLKTS(0), // 1-bit input: User CCLK 3-state enable input.
    .USRDONEO(USRDONEO),   // 1-bit input: User DONE pin output control.
    .USRDONETS(USRDONETS)  // 1-bit input: User DONE 3-state enable output.
);

uart_tx 
#(
    .CLKS_PER_BIT(434)        //CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART) = 50M/115200 = 434
)
 uart_tx_inst
(
   .i_Clock(clk),                //input       i_Clock,
   .i_Tx_DV(tx_dv),                //input       i_Tx_DV,
   .i_Tx_Byte(tx_byte),              //input [7:0] i_Tx_Byte, 
   .o_Tx_Active(tx_active),            //output      o_Tx_Active,
   .o_Tx_Serial(UART_TX),            //output reg  o_Tx_Serial,
   .o_Tx_Done(tx_done)               //output      o_Tx_Done
);

uart_rx 
#(
    .CLKS_PER_BIT(434)        //CLKS_PER_BIT = (Frequency of i_Clock)/(Frequency of UART) = 50M/115200 = 434
)
 uart_rx_inst
(
   .i_Clock(clk),         //input        i_Clock,
   .i_Rx_Serial(UART_RX),         //input        i_Rx_Serial,
   .o_Rx_DV(rx_dv),         //output       o_Rx_DV,
   .o_Rx_Byte(rx_byte)          //output [7:0] o_Rx_Byte
);

uart_comm_state_machine uart_comm_state_machine_inst
(
    .clk(clk),                 //input                   clk,             	// Clock signal
    .rst(rst),                 //input                   rst,            	// Active-high, synchronous reset
    .macro_states(macro_states),                        //input  [3:0]            macro_states,
    .macro_states_valid(macro_states_valid),                        //input                   macro_states_valid,
    .macro_states_done(uart_macro_states_done),                        //output reg              macro_states_done,
    .rx_num_reg(rx_num),                        //output reg [31:0]       rx_num_reg,
    .rx_cnt(rx_cnt),                  //input  [15:0]           rx_cnt;
    .buff_wren(buff_wren),    //output reg              buff_wren,
    .o_Tx_DV(tx_dv),             //output reg              o_Tx_DV,
    .o_Tx_Byte(tx_byte),           //output [7:0]            o_Tx_Byte, 
    .i_Tx_Active(tx_active),         //input                   i_Tx_Active,
    .i_Tx_Done(tx_done),            //input                   i_Tx_Done
    .i_Rx_DV(rx_dv),                //input                   i_Rx_DV,
    .i_Rx_Byte(rx_byte)             //input  [7:0]            i_Rx_Byte
);

macro_state_machine macro_state_machine_inst
(
    .clk(clk),             //input                   clk,             	// Clock signal
    .rst(rst),             //input                   rst,            	// Active-high, synchronous reset
    .start(one_shot),             //input                   start,
    .macro_states(macro_states),             //output reg [3:0]        macro_states,
    .macro_states_valid(macro_states_valid),             //output reg              macro_states_valid,
    .uart_macro_states_done(uart_macro_states_done),             //input                   uart_macro_states_done,
    .flash_macro_states_done(flash_macro_states_done),      //input                   flash_macro_states_done
    .buff_prog_empty(buff_prog_empty),
    .rx_num(rx_num),            //input [31:0]            rx_num_reg
    .rx_cnt(rx_cnt),      //output reg [15:0]       rx_cnt,
    .addr_reg(spi_addr[31:0])    //output reg [31:0]       addr_reg,
);

fifo_uart_buff fifo_uart_buff_4096byte_inst
(
  .clk(clk),                  // input wire clk
  .srst(rst),                // input wire srst
  .din(rx_byte),                  // input wire [7 : 0] din
  .wr_en(rx_dv & buff_wren),              // input wire wr_en
  .rd_en(buff_rden),              // input wire rd_en
  .dout(spi_data),//buff_data),                // output wire [63 : 0] dout
  .full(buff_full),                // output wire full
  .empty(buff_empty),              // output wire empty
  .valid(),              // output wire valid
  .prog_empty(buff_prog_empty),    // output wire prog_empty
  .wr_rst_busy(),  // output wire wr_rst_busy
  .rd_rst_busy()  // output wire rd_rst_busy
);


ila_0 ila_0_inst (
    .clk(clk), // input wire clk

	.probe0(spi_fetch_dout), // input wire [63:0]  probe0  
	.probe1({spi_load, spi_fetch, spi_fetch_empty, spi_busy}), // input wire [3:0]  probe1 
	.probe2({start_addr[31:0], spi_addr[31:0]}), // input wire [63:0]  probe2 
	.probe3(spi_data), // input wire [63:0]  probe3 
	.probe4({rx_dv, rx_byte, tx_dv, tx_done, tx_active, tx_byte}), // input wire [19:0]  probe4 
	.probe5({buff_empty, led_cnt[3], buff_prog_empty, macro_states, macro_states_valid, flash_macro_states_done, uart_macro_states_done, rx_num}) // input wire [41:0]  probe5
);

always@(posedge clk)
begin
    rst = ~EOS || |button_out;
end

always@(posedge clk)
begin
    if(rst)
    begin
        one_shot_cnt = 0;
    end
    else if(&one_shot_cnt)
    begin
        one_shot_cnt = one_shot_cnt;
    end
    else
    begin
        one_shot_cnt = one_shot_cnt + 1;
    end
end

always@(posedge clk)
begin
    if(rst)
    begin
        one_shot = 0;
    end
    else if(one_shot_cnt == 29'h1FFFFFFE)
    begin
        one_shot = 1;
    end
    else if(one_shot_cnt == 29'h1FFFFFFF)
    begin
        one_shot = 0;
    end
end

always@(posedge clk)
begin
    led_cnt = led_cnt + 1;
end

assign LED = led_cnt[24];

endmodule
