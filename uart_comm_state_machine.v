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

parameter rcv_ack_text = {8'd78, 8'd117, 8'd109, 8'd98, 8'd101, 8'd114, 8'd32, 8'd111, 8'd102, 8'd32, 8'd52, 8'd107, 8'd66, 8'd121, 8'd116,
8'd101, 8'd32, 8'd80, 8'd97, 8'd99, 8'd107, 8'd97, 8'd103, 8'd101, 8'd115, 8'd32, 8'd76, 8'd101, 8'd102, 8'd116, 8'd58};
parameter rcv_ack_cnt = 31;

parameter IDLE      = 5'b00000;
parameter LdMenu    = 5'b00001;
parameter SdChar    = 5'b00010;
parameter CkBsyChar = 5'b00011;
parameter NxChar    = 5'b00100;
parameter QstAddr   = 5'b00101;
parameter QstDatLen = 5'b00110;
parameter RxNum     = 5'b00111;
parameter CkNum     = 5'b01000;
parameter RxEnd     = 5'b01001;
parameter LdCRLF    = 5'b01010;
parameter TxRxEnd   = 5'b01011;
parameter QstFile   = 5'b01100;
parameter RxFile    = 5'b01101;
parameter LdRcvAck  = 5'b01110;
parameter StartBCD  = 5'b01111;
parameter WtBCD     = 5'b10000;
parameter BCD2ASCII = 5'b10001;
parameter LdBCD     = 5'b10010;

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

reg [max_byte_num*8-1:0]        msg_text;
reg [7:0]                       msg_char_cnt;

reg [4:0]   states;

reg [3:0]   macro_states_reg;
reg         macro_states_busy;

reg [7:0]   rx_byte_reg;
reg [15:0]  rx_cnt_reg;
reg         bcd_start;
reg [19:0]  bcd_reg;
wire [19:0]   o_bcd;
wire        bcd_dv;
reg [39:0]  bcd_text;


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
      bcd_start = 0;
      bcd_text = 0;
      bcd_reg = 0;
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
            else if(macro_states_valid && macro_states == SetUARTAck)
               states <= LdCRLF;
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
                    BuffUART,
                    SetUARTAck :
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
                bcd_start = 0;
                bcd_text = 0;
                bcd_reg = 0;
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
         LdRcvAck : begin
            if (0)
               states <= IDLE;
            else
               states <= SdChar;

            msg_text = {rcv_ack_text, {(max_byte_num - rcv_ack_cnt){8'hFF}}};
            msg_char_cnt = rcv_ack_cnt;
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
            else if(msg_char_cnt == 1 && macro_states_reg == SetUARTAck && |rx_cnt_reg)
               states <= StartBCD;      // -> LdRcvAck;
            else if(msg_char_cnt == 1 && macro_states_reg == SetUARTAck && bcd_text == 0)
               states <= BCD2ASCII;     // -> LdBCD
            else if(msg_char_cnt == 1 && macro_states_reg == SetUARTAck)
               states <= TxRxEnd;
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
         StartBCD : begin
            if(0)
                states <= IDLE;
            else
                states <= WtBCD;

            bcd_start = 1;
            rx_cnt_reg = 0;
         end
         WtBCD : begin
            if(bcd_dv)
                states <= LdRcvAck;
            else
                states <= WtBCD;

            bcd_reg = o_bcd;
            bcd_start = 0;
         end
         BCD2ASCII : begin
            if (0)
               states <= IDLE;
            else
               states <= LdBCD;

            bcd_text[7:0] = 8'd48 + bcd_reg[3:0];
            bcd_text[15:8] = 8'd48 + bcd_reg[7:4];
            bcd_text[23:16] = 8'd48 + bcd_reg[11:8];
            bcd_text[31:24] = 8'd48 + bcd_reg[15:12];
            bcd_text[39:32] = 8'd48 + bcd_reg[19:16];
         end
         LdBCD : begin
            if (0)
               states <= IDLE;
            else
               states <= SdChar;

            msg_text = {bcd_text, {(max_byte_num - 5){8'hFF}}};
            msg_char_cnt = 5;
         end
        default : begin  // Fault Recovery
            states <= IDLE;

         end
      endcase

Binary_to_BCD
#(  .INPUT_WIDTH(16),
    .DECIMAL_DIGITS(5)
) Binary_to_BCD_inst
(
   .i_Clock(clk),             //input                         i_Clock,
   .i_Binary(rx_cnt_reg),             //input [INPUT_WIDTH-1:0]       i_Binary,
   .i_Start(bcd_start),          //input                         i_Start,
   //
   .o_BCD(o_bcd),            //output [DECIMAL_DIGITS*4-1:0] o_BCD,
   .o_DV(bcd_dv)      //output                        o_DV
);

endmodule

module Binary_to_BCD
  #(parameter INPUT_WIDTH = 16,
    parameter DECIMAL_DIGITS = 5)
  (
   input                         i_Clock,
   input [INPUT_WIDTH-1:0]       i_Binary,
   input                         i_Start,
   //
   output [DECIMAL_DIGITS*4-1:0] o_BCD,
   output                        o_DV
   );
   
  parameter s_IDLE              = 3'b000;
  parameter s_SHIFT             = 3'b001;
  parameter s_CHECK_SHIFT_INDEX = 3'b010;
  parameter s_ADD               = 3'b011;
  parameter s_CHECK_DIGIT_INDEX = 3'b100;
  parameter s_BCD_DONE          = 3'b101;
   
  reg [2:0] r_SM_Main = s_IDLE;
   
  // The vector that contains the output BCD
  reg [DECIMAL_DIGITS*4-1:0] r_BCD = 0;
    
  // The vector that contains the input binary value being shifted.
  reg [INPUT_WIDTH-1:0]      r_Binary = 0;
      
  // Keeps track of which Decimal Digit we are indexing
  reg [DECIMAL_DIGITS-1:0]   r_Digit_Index = 0;
    
  // Keeps track of which loop iteration we are on.
  // Number of loops performed = INPUT_WIDTH
  reg [7:0]                  r_Loop_Count = 0;
 
  wire [3:0]                 w_BCD_Digit;
  reg                        r_DV = 1'b0;                       
    
  always @(posedge i_Clock)
    begin
 
      case (r_SM_Main) 
  
        // Stay in this state until i_Start comes along
        s_IDLE :
          begin
            r_DV <= 1'b0;
             
            if (i_Start == 1'b1)
              begin
                r_Binary  <= i_Binary;
                r_SM_Main <= s_SHIFT;
                r_BCD     <= 0;
              end
            else
              r_SM_Main <= s_IDLE;
          end
                 
  
        // Always shift the BCD Vector until we have shifted all bits through
        // Shift the most significant bit of r_Binary into r_BCD lowest bit.
        s_SHIFT :
          begin
            r_BCD     <= r_BCD << 1;
            r_BCD[0]  <= r_Binary[INPUT_WIDTH-1];
            r_Binary  <= r_Binary << 1;
            r_SM_Main <= s_CHECK_SHIFT_INDEX;
          end          
         
  
        // Check if we are done with shifting in r_Binary vector
        s_CHECK_SHIFT_INDEX :
          begin
            if (r_Loop_Count == INPUT_WIDTH-1)
              begin
                r_Loop_Count <= 0;
                r_SM_Main    <= s_BCD_DONE;
              end
            else
              begin
                r_Loop_Count <= r_Loop_Count + 1;
                r_SM_Main    <= s_ADD;
              end
          end
                 
  
        // Break down each BCD Digit individually.  Check them one-by-one to
        // see if they are greater than 4.  If they are, increment by 3.
        // Put the result back into r_BCD Vector.  
        s_ADD :
          begin
            if (w_BCD_Digit > 4)
              begin                                     
                r_BCD[(r_Digit_Index*4)+:4] <= w_BCD_Digit + 3;  
              end
             
            r_SM_Main <= s_CHECK_DIGIT_INDEX; 
          end       
         
         
        // Check if we are done incrementing all of the BCD Digits
        s_CHECK_DIGIT_INDEX :
          begin
            if (r_Digit_Index == DECIMAL_DIGITS-1)
              begin
                r_Digit_Index <= 0;
                r_SM_Main     <= s_SHIFT;
              end
            else
              begin
                r_Digit_Index <= r_Digit_Index + 1;
                r_SM_Main     <= s_ADD;
              end
          end
         
  
  
        s_BCD_DONE :
          begin
            r_DV      <= 1'b1;
            r_SM_Main <= s_IDLE;
          end
         
         
        default :
          r_SM_Main <= s_IDLE;
            
      endcase
    end // always @ (posedge i_Clock)  
 
   
  assign w_BCD_Digit = r_BCD[r_Digit_Index*4 +: 4];
       
  assign o_BCD = r_BCD;
  assign o_DV  = r_DV;
      
endmodule // Binary_to_BCD