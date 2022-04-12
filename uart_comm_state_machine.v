`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
module uart_comm_state_machine
(
    input                   clk,             	// Clock signal
    input                   rst,            	// Active-high, synchronous reset
    input  [3:0]            macro_states,
    input                   macro_states_valid,
    output reg              macro_states_done,
    input  [15:0]           rx_cnt,
    output reg [31:0]       rx_num_reg,
    output reg              buff_wren,
    output reg              o_Tx_DV,
    output [7:0]            o_Tx_Byte, 
    input                   i_Tx_Active,
    input                   i_Tx_Done,
    input                   i_Rx_DV,
    input  [7:0]            i_Rx_Byte
);

parameter max_byte_num = 256;
parameter menu_text = {8'd67, 8'd104, 8'd111, 8'd111, 8'd115, 8'd101, 8'd32, 8'd102, 8'd114, 8'd111, 8'd109, 8'd32, 8'd111, 8'd112, 8'd116, 8'd105, 8'd111, 8'd110, 8'd115, 8'd32, 8'd98, 8'd101, 8'd108, 8'd111, 8'd119, 8'd58, 8'd13, 8'd10,
8'd49, 8'd58, 8'd32, 8'd82, 8'd101, 8'd97, 8'd100, 8'd32, 8'd81, 8'd117, 8'd97, 8'd100, 8'd32, 8'd83, 8'd80, 8'd73, 8'd32, 8'd102, 8'd108, 8'd97, 8'd115, 8'd104, 8'd32, 8'd73, 8'd68, 8'd13, 8'd10,
8'd50, 8'd58, 8'd32, 8'd69, 8'd114, 8'd97, 8'd115, 8'd101, 8'd32, 8'd81, 8'd117, 8'd97, 8'd100, 8'd32, 8'd83, 8'd80, 8'd73, 8'd32, 8'd102, 8'd108, 8'd97, 8'd115, 8'd104, 8'd13, 8'd10,
8'd51, 8'd58, 8'd32, 8'd66, 8'd108, 8'd97, 8'd110, 8'd107, 8'd32, 8'd67, 8'd104, 8'd101, 8'd99, 8'd107, 8'd32, 8'd81, 8'd117, 8'd97, 8'd100, 8'd32, 8'd83, 8'd80, 8'd73, 8'd32, 8'd102, 8'd108, 8'd97, 8'd115, 8'd104, 8'd13, 8'd10,
8'd52, 8'd58, 8'd32, 8'd80, 8'd114, 8'd111, 8'd103, 8'd114, 8'd97, 8'd109, 8'd47, 8'd86, 8'd101, 8'd114, 8'd105, 8'd102, 8'd121, 8'd32, 8'd40, 8'd42, 8'd46, 8'd98, 8'd105, 8'd110, 8'd41, 8'd13, 8'd10,
8'd53, 8'd58, 8'd32, 8'd82, 8'd101, 8'd97, 8'd100, 8'd32, 8'd81, 8'd117, 8'd97, 8'd100, 8'd32, 8'd83, 8'd80, 8'd73, 8'd32, 8'd102, 8'd108, 8'd97, 8'd115, 8'd104, 8'd13, 8'd10};
parameter                       menu_text_cnt = 162;

parameter rx_num_reg_text = {8'd83, 8'd116, 8'd97, 8'd114, 8'd116, 8'd32, 8'd65, 8'd100, 8'd100, 8'd114, 8'd101, 8'd115, 8'd115, 8'd32, 8'd105, 8'd110, 8'd32, 8'd72, 8'd69, 8'd88, 8'd58};
parameter rx_num_reg_text_cnt = 21;

parameter data_length_text = {8'd84, 8'd111, 8'd116, 8'd97, 8'd108, 8'd32, 8'd68, 8'd97, 8'd116, 8'd97, 8'd32, 8'd76, 8'd101, 8'd110, 8'd103, 8'd116, 8'd104, 8'd32,
8'd40, 8'd98, 8'd121, 8'd116, 8'd101, 8'd41, 8'd32, 8'd105, 8'd110, 8'd32, 8'd72, 8'd69, 8'd88, 8'd58};
parameter data_length_text_cnt = 32;

parameter quest_file_text = {8'd83, 8'd101, 8'd110, 8'd100, 8'd32, 8'd42, 8'd46, 8'd98, 8'd105, 8'd110, 8'd32, 8'd70, 8'd105, 8'd108, 8'd101, 8'd32, 8'd105, 8'd110, 8'd32,
8'd52, 8'd48, 8'd57, 8'd54, 8'd45, 8'd98, 8'd121, 8'd116, 8'd101, 8'd32, 8'd80, 8'd97, 8'd99, 8'd107, 8'd97, 8'd103, 8'd101, 8'd115, 8'd58};
parameter quest_file_text_cnt = 38;

parameter CRLF = {8'd13, 8'd10};
parameter CRLF_cnt = 2;

parameter IDLE      = 4'b0000;
parameter LdMenu    = 4'b0001;
parameter SdChar    = 4'b0010;
parameter CkBsyChar = 4'b0011;
parameter NxChar    = 4'b0100;
parameter QstAddr   = 4'b0101;
parameter QstDatLen = 4'b0110;
parameter RxNum     = 4'b0111;
parameter CkNum     = 4'b1000;
parameter RxEnd     = 4'b1001;
parameter LdCRLF    = 4'b1010;
parameter TxRxEnd   = 4'b1011;
parameter QstFile   = 4'b1100;
parameter RxFile    = 4'b1101;
parameter TBD9      = 4'b1110;
parameter TBD0      = 4'b1111;

//macro_states
parameter SetUARTMenu   = 4'h1;
parameter SetUARTAddr   = 4'h2;
parameter SetUARTData   = 4'h3;
parameter SendUARTNewLn = 4'h4;
parameter WaitUARTMsg   = 4'h5;
parameter SetUARTRdFl   = 4'h6;
parameter BuffUART      = 4'h7;

parameter FlashERS4kB   = 4'hA;
parameter FlashRdID     = 4'hB;
parameter FlashWrPg     = 4'hC;
parameter FlashRdPg     = 4'hD;
parameter FlashRdSR     = 4'hE;
parameter FlashRdFR     = 4'hF;

reg [max_byte_num*8-1:0]        msg_text;
reg [7:0]                       msg_char_cnt;

reg [3:0]   states;

reg [3:0]   macro_states_reg;
reg         macro_states_busy;

reg [7:0]   rx_byte_reg;
reg [15:0]  rx_cnt_reg;

assign o_Tx_Byte = msg_text[(max_byte_num*8-1) : (max_byte_num*8-8)];

always @(posedge clk)
   if (rst) begin
      states <= IDLE;

      o_Tx_DV = 0;
      macro_states_reg = 0;
      macro_states_done = 0;
      macro_states_busy = 0;
      rx_num_reg = 0;
      rx_cnt_reg = 0;
      buff_wren = 0;
   end
   else
      case (states)
         IDLE : begin
            if (macro_states_valid && macro_states == SetUARTMenu)
               states <= LdMenu;
            else if(macro_states_valid && macro_states == SetUARTAddr)
               states <= QstAddr;
            else if(macro_states_valid && macro_states == SetUARTData)
               states <= QstDatLen;
            else if(macro_states_valid && macro_states == SendUARTNewLn)
               states <= LdCRLF;
            else if(macro_states_valid && macro_states == WaitUARTMsg)
               states <= RxNum;
            else if(macro_states_valid && macro_states == SetUARTRdFl)
               states <= QstFile;
            else if(macro_states_valid && macro_states == BuffUART)
               states <= RxFile;
            else
               states <= IDLE;

            if(macro_states_valid)
            begin
                case (macro_states)
                    SetUARTMenu,
                    SetUARTAddr,
                    SetUARTData,
                    SendUARTNewLn,
                    WaitUARTMsg,
                    SetUARTRdFl,
                    BuffUART :
                    begin
                        macro_states_reg = macro_states;
                        macro_states_busy = 1;
                        rx_cnt_reg = rx_cnt;
                    end
                    default :
                    begin
                        macro_states_busy = 0;
                    end
                endcase
            end
            else
            begin
                macro_states_done = 0;
                rx_num_reg = 0;
                macro_states_busy = 0;
            end
         end
         LdMenu : begin
            if (0)
               states <= IDLE;
            else
               states <= SdChar;

            msg_text = {menu_text, {(max_byte_num - menu_text_cnt){8'hFF}}};
            msg_char_cnt = menu_text_cnt;
         end
         QstAddr : begin
            if (0)
               states <= IDLE;
            else
               states <= SdChar;

            msg_text = {rx_num_reg_text, {(max_byte_num - rx_num_reg_text_cnt){8'hFF}}};
            msg_char_cnt = rx_num_reg_text_cnt;
         end
         QstDatLen : begin
            if (0)
               states <= IDLE;
            else
               states <= SdChar;

            msg_text = {data_length_text, {(max_byte_num - data_length_text_cnt){8'hFF}}};
            msg_char_cnt = data_length_text_cnt;
         end
         QstFile : begin
            if (0)
               states <= IDLE;
            else
               states <= SdChar;

            msg_text = {quest_file_text, {(max_byte_num - quest_file_text_cnt){8'hFF}}};
            msg_char_cnt = quest_file_text_cnt;
         end
         LdCRLF : begin
            if (0)
               states <= IDLE;
            else
               states <= SdChar;

            msg_text = {CRLF, {(max_byte_num - CRLF_cnt){8'hFF}}};
            msg_char_cnt = CRLF_cnt;
         end
         SdChar : begin
            if (0)
               states <= IDLE;
            else
               states <= CkBsyChar;

            o_Tx_DV = 1;
         end
         CkBsyChar : begin
            if(o_Tx_DV)
               states <= CkBsyChar;
            else if (i_Tx_Active)
               states <= CkBsyChar;
            else if(i_Tx_Done)
               states <= NxChar;

            o_Tx_DV = 0;
         end
         NxChar : begin
            if(msg_char_cnt == 1 && (macro_states_reg == SetUARTMenu ||
                                     macro_states_reg == SetUARTAddr ||
                                     macro_states_reg == SetUARTData ||
                                     macro_states_reg == SendUARTNewLn ||
                                     macro_states_reg == SetUARTRdFl))
               states <= TxRxEnd;
            else if(msg_char_cnt == 1 && macro_states_reg == WaitUARTMsg)
               states <= RxNum;
            else
               states <= SdChar;

            msg_text = msg_text << 8;
            msg_char_cnt = msg_char_cnt - 1;
         end
         TxRxEnd : begin
            if(0)
               states <= IDLE;
            else
               states <= IDLE;

            macro_states_reg = 0;
            macro_states_busy = 0;
            macro_states_done = 1;
         end
         RxNum : begin
            if(i_Rx_DV)
            begin
                case (i_Rx_Byte)
                    8'd48,
                    8'd49,
                    8'd50, 
                    8'd51, 
                    8'd52, 
                    8'd53,
                    8'd54,
                    8'd55,
                    8'd56,
                    8'd57,
                    8'd65, 8'd97,
                    8'd66, 8'd98,
                    8'd67, 8'd99,
                    8'd68, 8'd100,
                    8'd69, 8'd101,
                    8'd70, 8'd102:
                        states <= CkNum;
                    8'd13:
                        states <= TxRxEnd;
                    default :
                        states <= RxNum;
                endcase    
            end

            rx_byte_reg = i_Rx_Byte;
         end
         CkNum : begin
            if (0)
               states <= RxNum;
            else
               states <= SdChar;

            msg_text = {rx_byte_reg, {(max_byte_num - 1){8'hFF}}};
            msg_char_cnt = 1;

            case (rx_byte_reg)
                8'd48:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 0;
                end
                8'd49:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 1;
                end
                8'd50: 
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 2;
                end
                8'd51: 
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 3;
                end
                8'd52: 
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 4;
                end
                8'd53:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 5;
                end
                8'd54:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 6;
                end
                8'd55:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 7;
                end
                8'd56:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 8;
                end
                8'd57:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 9;
                end
                8'd65, 8'd97:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 4'hA;
                end
                8'd66, 8'd98:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 4'hB;
                end
                8'd67, 8'd99:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 4'hC;
                end
                8'd68, 8'd100:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 4'hD;
                end
                8'd69, 8'd101:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 4'hE;
                end
                8'd70, 8'd102:
                begin
                    rx_num_reg = rx_num_reg << 4;
                    rx_num_reg[3:0] = 4'hF;
                end
                default :;
           endcase
         end
         RxEnd : begin
            if(0)
               states <= IDLE;
            else
               states <= IDLE;

            macro_states_reg = 0;
            macro_states_busy = 0;
            macro_states_done = 1;
            buff_wren = 0;
         end
         RxFile : begin
            if(i_Rx_DV && (rx_cnt_reg > 1))
                states <= RxFile;
            else if(i_Rx_DV)
                states <= RxEnd;

            if(i_Rx_DV)
                rx_cnt_reg = rx_cnt_reg - 1;
            buff_wren = 1;
         end
         default : begin  // Fault Recovery
            states <= IDLE;

         end
      endcase
endmodule 
