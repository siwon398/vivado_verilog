`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module fnd_4digit_cntr(
        input clk, reset_p,
        input [15:0] value,
        output [7:0] seg_7_an, seg_7_ca,
        output [3:0] com);
        
        reg [3:0] hex_value;
        
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));//분주기 속도 빨리하면 결과 안나와_이유는?    

    always @(posedge clk) begin
        case(com)
            4'b0111: hex_value = value[15:12];
            4'b1011: hex_value = value[11:8];     
            4'b1101: hex_value = value[7:4];   
            4'b1110: hex_value = value[3:0];   
        endcase
    end    
  
    decoder_7seg fnd (.hex_value(hex_value), .seg_7(seg_7_an));   
    assign  seg_7_ca = ~seg_7_an;
    
    endmodule
///////////////////////////////////////////////////////
 module button_cntr(
        input clk, reset_p,
        input btn,
        output btn_pe, btn_ne);
        
        reg [16:0] clk_div;//원래는 =0 없어
        wire clk_div_16;   
        reg [1:0]debounced_btn;
       
        always @ (posedge clk)      clk_div = clk_div +1;
        edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
      
        
        always @ (posedge clk, posedge reset_p) begin
            if(reset_p) debounced_btn=0;
            else if (clk_div_16) debounced_btn = btn;
        end   
         edge_detector_n ed2(.clk(clk), .reset_p(reset_p), 
                .cp(debounced_btn), .p_edge(btn_pe), .n_edge(btn_ne));
          
    endmodule    
    ///////////////////////////////////////////////////////////////////////

 module decoder_7seg(
    input[3:0] hex_value,
    output reg [7:0] seg_7);
    
    always @ (hex_value)begin
        case(hex_value)
                              //abcd_efgp
//            4'b0000: seg_7 = 8'b0000_0011;  //0
//            4'b0001: seg_7 = 8'b1001_1111;  //1
//            4'b0010: seg_7 = 8'b0010_0101;  //2
//            4'b0011: seg_7 = 8'b0000_1101;  //3
//            4'b0100: seg_7 = 8'b1001_1001;  //4
//            4'b0101: seg_7 = 8'b0100_1001;  //5
//            4'b0110: seg_7 = 8'b0100_0001;  //6
//            4'b0111: seg_7 = 8'b0001_1011;  //7
//            4'b1000: seg_7 = 8'b0000_0001;  //8
//            4'b1001: seg_7 = 8'b0001_1001;  //9
//            4'b1010: seg_7 = 8'b0001_0001;  //A
//            4'b1011: seg_7 = 8'b1100_0001;  //b
//            4'b1100: seg_7 = 8'b0110_0011;  //C
//            4'b1101: seg_7 = 8'b1000_0101;  //d
//            4'b1110: seg_7 = 8'b0110_0001;  //E
//            4'b1111: seg_7 = 8'b0111_0001;  //F
 4'b0000: seg_7 = 8'b1111_1100;  //0
 4'b0001: seg_7 = 8'b0110_0000;  //1
 4'b0010: seg_7 = 8'b1101_1010;  //2
 4'b0011: seg_7 = 8'b1111_0010;  //3
 4'b0100: seg_7 = 8'b0110_0110;  //4
 4'b0101: seg_7 = 8'b1011_0110;  //5
 4'b0110: seg_7 = 8'b1011_1110;  //6
 4'b0111: seg_7 = 8'b1110_0100;  //7
 4'b1000: seg_7 = 8'b1111_1110;  //8
 4'b1001: seg_7 = 8'b1110_0110;  //9
 4'b1010: seg_7 = 8'b1110_1110;  //A
 4'b1011: seg_7 = 8'b0011_1110;  //b
 4'b1100: seg_7 = 8'b1001_1100;  //C
 4'b1101: seg_7 = 8'b0111_1010;  //d
 4'b1110: seg_7 = 8'b1001_1110;  //E
 4'b1111: seg_7 = 8'b1000_1110;  //F
        endcase
    end
    endmodule
        