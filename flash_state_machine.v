`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Designed and Tested for MT25QU256
// Dual I/O and Quand I/O modes are not supported
// Extended Mode with Quad Output Fast Read and Quad Input Fast Program are supported
//////////////////////////////////////////////////////////////////////////////////
module flash_state_machine
(
    input                   clk,             	// Clock signal
    input                   rst,            	// Active-high, synchronous reset
    input  [3:0]            macro_states,
    input                   macro_states_valid,
    output reg              macro_states_done,
    input  [63:0]           addr_in,
    input  [63:0]           data_in,
    output reg              buff_rden,
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
	input					fetch_empty_in
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
parameter WtWENA    = 4'b1011;
parameter WtWrPg    = 4'b1100;
parameter RdFIFO    = 4'b1101;
parameter Done      = 4'b1110;
parameter TBD0      = 4'b1111;

//macro_states
parameter SetUARTMenu   = 4'h1;
parameter SetUARTAddr   = 4'h2;
parameter SetUARTData   = 4'h3;
parameter SendUARTNewLn = 4'h4;
parameter WaitUARTMsg   = 4'h5;
parameter SetUARTRdFl   = 4'h6;
parameter BuffUART      = 4'h7;

parameter FlashRdID     = 4'hB;
parameter FlashWrPg     = 4'hC;
parameter FlashRdPg     = 4'hD;
parameter FlashRdSR     = 4'hE;
parameter FlashRdFR     = 4'hF;

reg         state_busy;
reg [3:0]   macro_states_reg;
reg [31:0]  addr_in_reg;
reg [5:0]   data_cnt;

reg [3:0]   states = IDLE;


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
      buff_rden <= 0;
      data_cnt <= 0;
      macro_states_done = 0;
   end
   else
      case (states)
         IDLE : begin
            if (macro_states_valid && macro_states == FlashRdID)
               states <= LdRdID;
            else if(macro_states_valid && macro_states == FlashWrPg)
               states <= LdWENA;
            else if(macro_states_valid && macro_states == FlashRdPg)
               states <= LdRdPg;
            else if(macro_states_valid && macro_states == FlashRdSR)
               states <= LdRdSR;
			else if(macro_states_valid && macro_states == FlashRdFR)
			   states <= LdRdFSR;
            else
               states <= IDLE;

            if(macro_states_valid)
            begin
                macro_states_reg = macro_states;
                addr_in_reg = addr_in[31:0];
            end
            state_busy = 1;
            macro_states_done = 0;
         end
         LdWENA : begin
            if (1)
               states <= WtWENA;
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
         end
         WtWENA : begin
            if (spi_busy_in)
               states <= WtWENA;
            else if(load_out)
               states <= WtWENA;
            else
               states <= RdFIFO;

            load_out = 0;
         end
         RdFIFO : begin
            if (1)
               states <= LdWrPg;
            else
               states <= RdFIFO;

            buff_rden = 1;
            load_out = 0;
         end
         LdWrPg : begin
            if(data_cnt == 31 && load_out)
			   states <= WtWrPg;
            else
               states <= LdWrPg;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 32;
            dummy_len_out = 0;
            data_len_out = 512;
            command_out = 8'h34;	//4-BYTE QUAD INPUT FAST PROGRAM
            addr_out = addr_in_reg;
            data_out = data_in;
            tristate_out = 0;
            fetch_out = 0;
            if(data_cnt < 31)
                buff_rden = 1;
            else
                buff_rden = 0;
            data_cnt = data_cnt + 1;
         end
         WtWrPg : begin
            if (spi_busy_in)
               states <= WtWrPg;
            else if(load_out)
               states <= WtWrPg;
            else
               states <= LdRdSR;

            buff_rden = 0;
            load_out = 0;
            data_cnt = 0;
         end
         LdRdSR : begin
            if (1)                  //(macro_states_reg == FlashWrPg)
               states <= WtRdSR;
            else
               states <= IDLE;

            state_busy = 1;
            load_out = 1;
            command_len_out = 8;
            addr_len_out = 0;
            dummy_len_out = 0;
            data_len_out = 16;
            command_out = 8'h05;    //READ STATUS REGISTER 
            addr_out = 0;
            data_out = 0;
            tristate_out = 1;
            fetch_out = 0;
         end
         WtRdSR : begin
            if (spi_busy_in)
               states <= WtRdSR;
            else if(load_out)
               states <= WtRdSR;
            else 
               states <= FetchSR;

            load_out = 0;
         end
         FetchSR : begin
            if (fetch_empty_in)
               states <= CkBsySR;
            else
               states <= FetchSR;

            fetch_out = 1;
         end
         CkBsySR : begin
            if (fetch_din[37] | fetch_din[33]) 
               states <= LdRdSR;
            else
               states <= Done;

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
         end
         LdRdID : begin
            if (1)
               states <= Done;
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
         end
         Done : begin
            if (1)
               states <= IDLE;
            else
               states <= IDLE;

            state_busy = 1;
            macro_states_done = 1;
         end
         default : begin  // Fault Recovery
            states <= IDLE;

            state_busy = 0;
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
         end
      endcase
endmodule 
