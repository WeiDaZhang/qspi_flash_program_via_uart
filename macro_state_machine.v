`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module macro_state_machine
(
    input                   clk,             	// Clock signal
    input                   rst,            	// Active-high, synchronous reset
    input                   start,
    output reg [3:0]        macro_states,
    output reg              macro_states_valid,
    input                   uart_macro_states_done,
    input                   flash_macro_states_done,
    input                   buff_prog_empty,
    input [31:0]            rx_num,
    output reg [15:0]       rx_cnt,
    output reg [31:0]       addr_reg,
    output                  pg_cnt
);

reg [31:0]       data_len_reg;
reg [23:0]       sec4kB_len_reg;
reg [23:0]       sec4kB_len_cnt;
reg [31:0]       start_addr_reg;

parameter IDLE       = 5'b00000;
parameter SetMenu    = 5'b00110;
parameter WtSMUEnd   = 5'b00001;
parameter QstMenu    = 5'b01001;
parameter WtQMuEnd   = 5'b00100;
parameter SetQMLn    = 5'b01010;
parameter WtSQMLnEnd = 5'b00101;
parameter SetAddr    = 5'b01101;
parameter WtSAddrEnd = 5'b01011;
parameter QstAddr    = 5'b00111;
parameter WtQAddrEnd = 5'b00010;
parameter SAddrLn    = 5'b01110;
parameter WtSADLnEnd = 5'b01111;
parameter SetDatLen  = 5'b01100;
parameter WtSDataEnd = 5'b10000;
parameter QstLen     = 5'b01000;
parameter WtQLenEnd  = 5'b00011;
parameter SDataLn    = 5'b10001;
parameter WtSDaLnEnd = 5'b10010;
parameter SetReadFl  = 5'b10011;
parameter WtSRdFlEnd = 5'b10100;
parameter Qst4kFl    = 5'b10101;
parameter WtQ4kFlEnd = 5'b10110;
parameter SetFlashWrPg = 5'b10111;
parameter WtFshPgEnd = 5'b11000;
parameter Calc4kBSec = 5'b11001;
parameter ERS4kBSec  = 5'b11010;
parameter WtERs4kBSec = 5'b11011;
parameter SetAck      = 5'b11100;
parameter WtSSetAck   = 5'b11101;

//macro_states
parameter SetUARTMenu   = 4'h1;
parameter SetUARTAddr   = 4'h2;
parameter SetUARTData   = 4'h3;
parameter SendUARTNewLn = 4'h4;
parameter WaitUARTMsg   = 4'h5;
parameter SetUARTRdFl   = 4'h6;
parameter BuffUART      = 4'h7;
parameter SetUARTAck    = 4'h8;

parameter FlashERS4kB   = 4'hA;
parameter FlashRdID     = 4'hB;
parameter FlashWrPg     = 4'hC;
parameter FlashRdPg     = 4'hD;
parameter FlashRdSR     = 4'hE;
parameter FlashRdFR     = 4'hF;

//Flash
parameter PgByteWidth       = 8;
parameter PgByteCnt         = 2**PgByteWidth;
parameter Sect4kBWidth      = 12;
parameter Sect4kBCnt        = 2**Sect4kBWidth;

reg [31:0]  rx_num_reg;
reg [31:0]  pg_cnt;
reg         SecRcvAck;

reg [4:0]   states;
always @(posedge clk)
   if (rst) begin
      states <= IDLE;

      macro_states = 0;
      macro_states_valid = 0;
      rx_num_reg = 0;
      pg_cnt = 0;
      SecRcvAck = 0;
   end
   else
      case (states)
         IDLE : begin
            if (start == 1)
               states <= SetMenu;
            else
               states <= IDLE;
         end
         SetMenu : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSMUEnd;

            macro_states = SetUARTMenu;
            macro_states_valid = 1;
         end
         WtSMUEnd : begin
            if (macro_states_valid)
               states <= WtSMUEnd;
            else if (~uart_macro_states_done)
               states <= WtSMUEnd;
            else if(uart_macro_states_done)
               states <= QstMenu;

            macro_states_valid = 0;
         end
         QstMenu : begin
            if (0)
               states <= IDLE;
            else
               states <= WtQMuEnd;

            macro_states = WaitUARTMsg;
            macro_states_valid = 1;
         end
         WtQMuEnd : begin
            if (macro_states_valid)
               states <= WtQMuEnd;
            else if (~uart_macro_states_done)
               states <= WtQMuEnd;
            else if(uart_macro_states_done)
               states <= SetQMLn;

            macro_states_valid = 0;
            if(uart_macro_states_done)
                rx_num_reg = rx_num;
         end
         SetQMLn : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSQMLnEnd;

            macro_states = SendUARTNewLn;
            macro_states_valid = 1;
         end
         WtSQMLnEnd : begin
            if (macro_states_valid)
               states <= WtSQMLnEnd;
            else if (~uart_macro_states_done)
               states <= WtSQMLnEnd;
            else if(uart_macro_states_done && rx_num_reg[7:0] == 4)
               states <= SetAddr;
            else if(uart_macro_states_done)
               states <= SetMenu;

            macro_states_valid = 0;
         end
         SetAddr : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSAddrEnd;

            macro_states = SetUARTAddr;
            macro_states_valid = 1;
         end
         WtSAddrEnd : begin
            if (macro_states_valid)
               states <= WtSAddrEnd;
            else if (~uart_macro_states_done)
               states <= WtSAddrEnd;
            else if(uart_macro_states_done)
               states <= QstAddr;

            macro_states_valid = 0;
         end
         QstAddr : begin
            if (0)
               states <= IDLE;
            else
               states <= WtQAddrEnd;

            macro_states = WaitUARTMsg;
            macro_states_valid = 1;
         end
         WtQAddrEnd : begin
            if (macro_states_valid)
               states <= WtQAddrEnd;
            else if (~uart_macro_states_done)
               states <= WtQAddrEnd;
            else if(uart_macro_states_done)
               states <= SAddrLn;

            macro_states_valid = 0;
            if(uart_macro_states_done)
                rx_num_reg = rx_num;
         end
         SAddrLn : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSADLnEnd;

            macro_states = SendUARTNewLn;
            macro_states_valid = 1;
         end
         WtSADLnEnd : begin
            if (macro_states_valid)
               states <= WtSADLnEnd;
            else if (~uart_macro_states_done)
               states <= WtSADLnEnd;
            else if(uart_macro_states_done)
               states <= SetDatLen;

            addr_reg = rx_num_reg;
            start_addr_reg = rx_num_reg;
            macro_states_valid = 0;
         end
         SetDatLen : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSDataEnd;

            macro_states = SetUARTData;
            macro_states_valid = 1;
         end
         WtSDataEnd : begin
            if (macro_states_valid)
               states <= WtSDataEnd;
            else if (~uart_macro_states_done)
               states <= WtSDataEnd;
            else if(uart_macro_states_done)
               states <= QstLen;

            macro_states_valid = 0;
         end
         QstLen : begin
            if (0)
               states <= IDLE;
            else
               states <= WtQLenEnd;

            macro_states = WaitUARTMsg;
            macro_states_valid = 1;
         end
         WtQLenEnd : begin
            if (macro_states_valid)
               states <= WtQLenEnd;
            else if (~uart_macro_states_done)
               states <= WtQLenEnd;
            else if(uart_macro_states_done)
               states <= SDataLn;

            macro_states_valid = 0;
            if(uart_macro_states_done)
                rx_num_reg = rx_num;
         end
         SDataLn : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSDaLnEnd;

            macro_states = SendUARTNewLn;
            macro_states_valid = 1;
         end
         WtSDaLnEnd : begin
            if (macro_states_valid)
               states <= WtSDaLnEnd;
            else if (~uart_macro_states_done)
               states <= WtSDaLnEnd;
            else if(uart_macro_states_done)
               states <= Calc4kBSec;

            data_len_reg = rx_num_reg;
            macro_states_valid = 0;
         end
         Calc4kBSec : begin
            if (0)
               states <= IDLE;
            else
               states <= ERS4kBSec;

            sec4kB_len_reg = (data_len_reg >> Sect4kBWidth) | 24'b1;
            sec4kB_len_cnt = (data_len_reg >> Sect4kBWidth) | 24'b1;
         end
         ERS4kBSec : begin
            if (0)
               states <= IDLE;
            else
               states <= WtERs4kBSec;

            macro_states = FlashERS4kB;
            macro_states_valid = 1;
         end
         WtERs4kBSec : begin
            if (macro_states_valid)
               states <= WtERs4kBSec;
            else if (~flash_macro_states_done)
               states <= WtERs4kBSec;
            else if(flash_macro_states_done && sec4kB_len_cnt == 1)
               states <= SetReadFl;
            else if(flash_macro_states_done)
               states <= ERS4kBSec;

            macro_states_valid = 0;
            if(flash_macro_states_done)
            begin
                addr_reg = addr_reg + Sect4kBCnt;
                sec4kB_len_cnt = sec4kB_len_cnt - 1;
            end
         end
         SetReadFl : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSRdFlEnd;

            macro_states = SetUARTRdFl;
            macro_states_valid = 1;
         end
         WtSRdFlEnd : begin
            if (macro_states_valid)
               states <= WtSRdFlEnd;
            else if (~uart_macro_states_done)
               states <= WtSRdFlEnd;
            else if(uart_macro_states_done)
               states <= Qst4kFl;

            if(uart_macro_states_done)
            begin
                addr_reg = start_addr_reg;
                sec4kB_len_cnt = sec4kB_len_reg;
            end
            macro_states_valid = 0;
         end
         Qst4kFl : begin
            if (0)
               states <= IDLE;
            else
               states <= WtQ4kFlEnd;

            macro_states = BuffUART;
            macro_states_valid = 1;
            rx_cnt = Sect4kBCnt;
            pg_cnt = 32'h1 << (Sect4kBWidth - PgByteWidth);
            SecRcvAck = 0;
         end
         WtQ4kFlEnd : begin
            if (macro_states_valid)
               states <= WtQ4kFlEnd;
            else if(~buff_prog_empty)
                states = SetFlashWrPg;
            else if(pg_cnt == 0 && SecRcvAck)
                states = SetAck;

            if(uart_macro_states_done)
            begin
                SecRcvAck = 1;
                sec4kB_len_cnt = sec4kB_len_cnt - 1;
            end
            macro_states_valid = 0;
         end
         SetFlashWrPg : begin
            if (0)
               states <= SetFlashWrPg;
            else
                states = WtFshPgEnd;

            if(uart_macro_states_done)
            begin
                SecRcvAck = 1;
                sec4kB_len_cnt = sec4kB_len_cnt - 1;
            end
            macro_states = FlashWrPg;
            macro_states_valid = 1;
         end
         WtFshPgEnd : begin
            if (macro_states_valid)
               states <= WtFshPgEnd;
            else if(flash_macro_states_done)
                states = WtQ4kFlEnd;

            macro_states_valid = 0;
            if(flash_macro_states_done)
            begin
                addr_reg = addr_reg + PgByteCnt;
                pg_cnt = pg_cnt - 1;
            end
            if(uart_macro_states_done)
            begin
                SecRcvAck = 1;
                sec4kB_len_cnt = sec4kB_len_cnt - 1;
            end
         end
         SetAck : begin
            if (0)
               states <= IDLE;
            else
               states <= WtSSetAck;

            macro_states = SetUARTAck;
            macro_states_valid = 1;
            rx_cnt = sec4kB_len_cnt;
         end
         WtSSetAck : begin
            if (macro_states_valid)
               states <= WtSSetAck;
            else if (~uart_macro_states_done)
               states <= WtSSetAck;
            else if(uart_macro_states_done && sec4kB_len_cnt == 1)
               states <= IDLE;
            else if(uart_macro_states_done)
               states <= Qst4kFl;

            macro_states_valid = 0;
         end
         default : begin  // Fault Recovery
            states <= IDLE;

         end
      endcase

endmodule 
