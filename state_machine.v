`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Designed and Tested for MT25QU256
// Dual I/O and Quand I/O modes are not supported
// Extended Mode with Quad Output Fast Read and Quad Input Fast Program are supported
//////////////////////////////////////////////////////////////////////////////////
module state_machine
(
    input                   clk,             	// Clock signal
    input                   rst,            	// Active-high, synchronous reset
    input  [4:0]            start_in,
    output reg              load_out,            // Active-high, synchronous load
    input                   load_full_in,            // Active-high, synchronous full
	output reg [7:0]        command_len_out,		// command length at SPI output width
	output reg [7:0]        addr_len_out,		// addr length at SPI output width
	output reg [7:0]		dummy_len_out,		// dummy cycles
	output reg [15:0]       data_len_out,        // data length at SPI output width
	output reg [31:0]       command_out,
	output reg [63:0]       addr_out,
	output reg [63:0]       data_out,
    output reg              tristate_out,        //1'b1 for flash to fpga, 1'b0 for fpga to flash
	input                   spi_busy_in,
	input	[63:0]			fetch_din,
	output reg 				fetch_out,
	input					fetch_empty_in,
	output reg              LED
);

parameter IDLE      = 4'b0000;
parameter LdRdFSR   = 4'b0001;      //Load Read Flag Statue Register
parameter LdRdSR    = 4'b0010;      //Load Read Statue Register
parameter WtRdSR    = 4'b0011;      //Wait Read Statue Register
parameter FetchSR   = 4'b0100;      //Fetch Statue Register
parameter CkBsySR   = 4'b0101;      //Check Busy Statue Register
parameter LdRdID    = 4'b0110;
parameter LdRdPg    = 4'b0111;		//Load Read Page of 256-Byte
parameter LdWENA    = 4'b1000;		//Load Write Enable CMD
parameter LdWDIS    = 4'b1001;		//Load Write Disable CMD
parameter LdWrPg    = 4'b1010;		//Load Write Page
parameter TBD6      = 4'b1011;
parameter TBD7      = 4'b1100;
parameter TBD8      = 4'b1101;
parameter TBD9      = 4'b1110;
parameter TBD0      = 4'b1111;

reg         state_busy;
reg [4:0]   start_reg;

reg [3:0]   states = IDLE;

reg	[6:0]	rom_addr;
wire [63:0]	rom_dout;

dist_mem_gen_0 dist_mem_gen_rom (
  .a(rom_addr),      // input wire [5 : 0] a
  .spo(rom_dout)  // output wire [63 : 0] spo
);


always @(posedge clk)
   if (rst) begin
      states <= IDLE;
      state_busy = 0;
      load_out <= 0;
      command_len_out <= 0;
      addr_len_out <= 0;
      dummy_len_out <= 0;
      data_len_out <= 0;
      command_out <= 0;
      addr_out <= 0;
      data_out <= 0;
      tristate_out <= 1;
      fetch_out <= 0;
      LED = 0;
      start_reg = 0;
	  rom_addr = 0;
   end
   else
      case (states)
         IDLE : begin
            if (start_in[0])        //CENTRE
               states <= LdRdSR;
            else if(start_in[1])    //North
               states <= LdWrPg;
            else if(start_in[2])    //South
               states <= LdRdPg;
            else if(start_in[3])    //West
               states <= LdWENA;
			else if(start_in[4])     //East
			   states <= LdWDIS;
            else
               states <= IDLE;

            start_reg = start_in;
            state_busy = 0;
            load_out <= 0;
            command_len_out <= 0;
            addr_len_out <= 0;
            dummy_len_out <= 0;
            data_len_out <= 0;
            command_out <= 0;
            addr_out <= 0;
            data_out <= 0;
            tristate_out <= 1;
            fetch_out <= 0;
            LED = 0;
         end
         LdWrPg : begin
            if (rom_addr == 0)
               states <= LdWrPg;
			else if(~|rom_addr[4:0] && load_out)
			   states <= WtRdSR;
            else
               states <= LdWrPg;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 32;
            dummy_len_out = 0;
            data_len_out = 512;
            command_out = 8'h34;	//4-BYTE QUAD INPUT FAST PROGRAM
            addr_out = 32'h002E0000 | {22'h0, rom_addr[6:5], 8'h0};
            data_out = rom_dout;
            tristate_out = 0;
            fetch_out = 0;
            LED = 0;
			rom_addr = rom_addr + 1;
         end
         LdWENA : begin
            if (1)
               states <= WtRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 0;
            command_out = 8'h06;	//WRITE ENABLE
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
         LdWDIS : begin
            if (1)
               states <= WtRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 0;
            command_out = 8'h04;	//WRITE DISABLE
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
         LdRdPg : begin
            if (1)
               states <= WtRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 32;
            dummy_len_out = 8;
            data_len_out = 512;
            command_out = 8'h6C;	//4-BYTE QUAD OUTPUT FAST READ
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
         LdRdFSR : begin
            if (1)
               states <= WtRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 16;
            command_out = 8'h70;	//READ FLAG STATUS REGISTER 
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
         LdRdID : begin
            if (1)
               states <= WtRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 160;
            command_out = 8'h9E;	//READ ID
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
        LdRdSR : begin
            if (1)
               states <= WtRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 16;
            command_out = 8'h05;
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
         WtRdSR : begin
            if (spi_busy_in)
               states <= WtRdSR;
            else if(load_out)
               states <= WtRdSR;
            else
               states <= FetchSR;

            state_busy = 1;
            load_out = 0;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 8;
            command_out = 8'h00;
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
         FetchSR : begin
            if (fetch_empty_in)
               states <= CkBsySR;
            else
               states <= FetchSR;

            state_busy = 1;
            load_out = 0;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 8;
            command_out = 8'h05;
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 1;
            LED = 0;
         end
         CkBsySR : begin
            if (0)			//((fetch_din[37] | fetch_din[33]) && start_reg[0])
               states <= LdRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 0;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 8;
            command_out = 8'h05;
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = ^fetch_din;
          end
         default : begin  // Fault Recovery
            states <= IDLE;

            state_busy = 1;
            load_out = 0;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 8;
            command_out = 8'h05;
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
            LED = 0;
         end
      endcase
endmodule 
