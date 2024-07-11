`timescale 1ns / 1ps

module D_flip_flop_n(
    input d,
    input clk,
    input reset_p,
    output reg q
);
    
     //     clk의 하강엣지에서 아래 조건문 1번 동작,
     // reset_p의 상승엣지에서 아래 조건문 1번 동작
    always @ (negedge clk or posedge reset_p) begin 
        if(reset_p) begin q=0; end  //reset우선
        else begin q = d;  end
    end
endmodule
////////////////////////////////////////////////
module D_flip_flop_p(
    input d,
    input clk,
    input reset_p,
    output reg q
);
     
    always @ (posedge clk or posedge reset_p) begin 
        if(reset_p) begin q=0; end
        else begin q = d;  end
    end
endmodule
///////////////////////////////////////////////
module T_flip_flop_n(
    input clk, reset_p,
    input t,
    output reg q
    );
    
    always @(negedge clk or posedge reset_p)begin
        if (reset_p) begin q = 0; end
        else begin 
            if(t) q = ~q;
            else q=q;
        end                
    end
    
endmodule
////////////////////////////////////////////////
module T_flip_flop_p(
    input clk, reset_p,
    input t,
    output reg q
    );
    
    always @(posedge clk or posedge reset_p)begin
        if (reset_p) begin q = 0; end
        else begin 
            if(t) q = ~q;
            else q=q;
        end                
    end
    
endmodule
////////////////////////////////////////////////
module up_counter_async(
    input clk, reset_p,
    output [3:0] count
    );
    
    T_flip_flop_n T0(.clk(clk),      .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_n T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_n T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_n T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
    
endmodule
/////////////////////////////////////////////////
module down_counter_async(
    input clk, reset_p,
    output [3:0] count
    );
    
    T_flip_flop_p T0(.clk(clk),      .reset_p(reset_p), .t(1), .q(count[0]));
    T_flip_flop_p T1(.clk(count[0]), .reset_p(reset_p), .t(1), .q(count[1]));
    T_flip_flop_p T2(.clk(count[1]), .reset_p(reset_p), .t(1), .q(count[2]));
    T_flip_flop_p T3(.clk(count[2]), .reset_p(reset_p), .t(1), .q(count[3]));
    
endmodule
/////////////////////////////////////////////
module up_counter_p(
    input clk, reset_p,
    output reg [3:0] count
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count =0;
        else count = count +1;
    end
endmodule        
//////////////////////////////////////
module up_counter_test_p32(
    input clk, reset_p,
    output [15:0] count
    );
    reg [31:0] count_32; //16비트는 너무 짧아서 32비트로 늘려
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count_32 =0;
        else count_32 = count_32 +1;
    end
    
    assign count = count_32[31:16];
endmodule        

///////////////////////////////////////
module decoder_7seg_test(
    input[3:0] hex_value,
    output reg [7:0] seg_7);
    
    always @ (hex_value)begin
        case(hex_value)
                              //abcd_efgp
            4'b0000: seg_7 = 8'b0000_0011;  //0
            4'b0001: seg_7 = 8'b1001_1111;  //1
            4'b0010: seg_7 = 8'b0010_0101;  //2
            4'b0011: seg_7 = 8'b0000_1101;  //3
            4'b0100: seg_7 = 8'b1001_1001;  //4
            4'b0101: seg_7 = 8'b0100_1001;  //5
            4'b0110: seg_7 = 8'b0100_0001;  //6
            4'b0111: seg_7 = 8'b0001_1011;  //7
            4'b1000: seg_7 = 8'b0000_0001;  //8
            4'b1001: seg_7 = 8'b0001_1001;  //9
            4'b1010: seg_7 = 8'b0001_0001;  //A
            4'b1011: seg_7 = 8'b1100_0001;  //b
            4'b1100: seg_7 = 8'b0110_0011;  //C
            4'b1101: seg_7 = 8'b1000_0101;  //d
            4'b1110: seg_7 = 8'b0110_0001;  //E
            4'b1111: seg_7 = 8'b0111_0001;  //F
        endcase
    end
    endmodule
        
//////////////////////////////////////
module up_counter_test_seg7(
    input clk, reset_p,
    output [15:0] count,
    output [7:0] seg_7
    );
    reg [31:0] count_32; //16비트는 너무 짧아서 32비트로 늘려
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count_32 =0;
        else count_32 = count_32 +1;
    end
    
    assign count = count_32[31:16];
    decoder_7seg_test fnd (.hex_value(count_32[28:25]), .seg_7(seg_7));
endmodule        

//////////////////////////////////////////
module down_counter_p #(parameter N=8)(
    input clk, reset_p, enable,
    output reg [N-1:0] count
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count =0;
        else begin
            if(enable) count = count -1;
            else count = count;
        end
    end
endmodule        
/////////////////////////////////////////    
    
module bcd_up_counter_p(
    input clk, reset_p,
    output reg [3:0] count
    );
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count =0;
        else begin
             count = count +1;
             if(count == 10) count = 0;
        end
    
    end
endmodule        
//////////////////////////////////////////////

module up_down_count(
    input clk, reset_p,
    input down_up,//1일때 다운카운터 동작, 0일때 업카운터 동작
    output reg [3:0] count);
    
    always @ (posedge clk or posedge reset_p)begin
        if (reset_p) count = 0;
        else begin
            if(down_up) count = count -1;//1일때 다운
            else count = count + 1;
        end
    end
endmodule  
////////////////////////////////////////////////////////////////////
module up_down_count_BCD(
    input clk, reset_p,
    input down_up,
    output reg [3:0] count);
    
    always @ (posedge clk or posedge reset_p)begin
        if (reset_p) count = 0;
        else begin
            if(down_up)
                if(count ==0) count =9;
                else count = count -1;
            else 
                if(count >= 9) count=0;
                else count = count +1;
        end   
    end
endmodule      
/////////////////////////////////////////////////////////////
module ring_counter(
    input clk, reset_p,
    output reg [3:0] q
    );
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) q = 4'b0001;
        else begin
            if       (q== 4'b0001) q= 4'b1000;
            else if  (q== 4'b1000) q= 4'b0100;
            else if  (q== 4'b0100) q= 4'b0010;
            else if  (q== 4'b0010) q= 4'b0001;
            else                   q= 4'b0001;
//            case(q)
//                4'b0001: q= 4'b1000;
//                4'b1000: q= 4'b0100;
//                4'b0100: q= 4'b0010;
//                4'b0010: q= 4'b0001;
//                default  q= 4'b0001;
//            endcase
         end
    end
endmodule
 ///////////////////////////////////////////////////////
 module ring_counter_fnd(
    input clk, reset_p,
    output reg [3:0] com
    );
    
    reg [16:0] clk_div;
    wire clk_div_16;
    always @(posedge clk) clk_div = clk_div +1;
    
    edge_detector_n ed (.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    always @(posedge clk_div[16] or posedge reset_p) begin //[13]숫자변화줘
        if(reset_p) com = 4'b1110;
        else begin
         case(com)
                4'b1110: com= 4'b1101;
                4'b1101: com= 4'b1011;
                4'b1011: com= 4'b0111;
                4'b0111: com= 4'b1110;
                default  com= 4'b1110;
            endcase   
         end
    end
endmodule
    //////////////////////////////////////
module up_counter_test_top_ring_seg7(      //3번째자리에서 8ㅂ터 시작, 4번째 자리 ef 23 67 ab
    input clk, reset_p,
    output [15:0] count,
    output [7:0] seg_7,
    output [3:0] com
    );
    
    reg [31:0] count_32; //16비트는 너무 짧아서 32비트로 늘려
    
    always @(posedge clk, posedge reset_p) begin
        if(reset_p) count_32 =0;
        else count_32 = count_32 +1;
    end
    
    assign count = count_32[31:16];
    
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));
    
    reg [3:0] value;
//    always @(com) begin // 조합논리회로
//        case(com)
//            4'b0111: value = count_32[32:28];
//            4'b1011: value = count_32[27:24];
//            4'b1101: value = count_32[23:20];
//            4'b1110: value = count_32[19:16];
//            default  value = count_32[19:16];
//        endcase
    
    
    
    always @(posedge clk) begin // 순서논리회로
        case(com)
            4'b0111: value = count_32[32:28];
            4'b1011: value = count_32[27:24];
            4'b1101: value = count_32[23:20];
            4'b1110: value = count_32[19:16];
        endcase
    end
    
    decoder_7seg_test fnd (.hex_value(value), .seg_7(seg_7));
endmodule        
/////////////////////////////////////////////////////////////

module ring_counter_led(
    input clk, reset_p,
    output reg [15:0] count
    );
    reg [31:0] clk_div;
    always @ ( posedge clk) clk_div = clk_div +1;

    always @ (posedge clk_div[31], posedge reset_p) begin

        if(reset_p) count = 16'b0000000000000001;
        else begin
           
            case(count)
            16'b0000000000000001: count = 16'b0000000000000010;
            16'b0000000000000010: count = 16'b0000000000000100;
            16'b0000000000000100: count = 16'b0000000000001000;
            16'b0000000000001000: count = 16'b0000000000010000;
            16'b0000000000010000: count = 16'b0000000000100000;
            16'b0000000000100000: count = 16'b0000000001000000;
            16'b0000000001000000: count = 16'b0000000010000000;
            16'b0000000010000000: count = 16'b0000000100000000;
            16'b0000000100000000: count = 16'b0000001000000000;
            16'b0000001000000000: count = 16'b0000010000000000;
            16'b0000010000000000: count = 16'b0000100000000000;
            16'b0000100000000000: count = 16'b0001000000000000;
            16'b0001000000000000: count = 16'b0010000000000000;
            16'b0010000000000000: count = 16'b0100000000000000;
            16'b0100000000000000: count = 16'b1000000000000000;
            16'b1000000000000000: count = 16'b0000000000000001;
            default               count = 16'b0000000000000001;
            endcase
         end
    end

endmodule
//////////////////////////////////////////////////////////////////

module ring_counter_led_shift(
    input clk, reset_p,
    output reg [15:0] count
    );
    
    reg [5:0] clk_div=0;
    
    always @ (posedge clk) clk_div = clk_div +1;
    
    always @ (posedge clk_div[3], posedge reset_p) begin
        if(reset_p) count = 16'b1;
        else begin
            count = {count[14:0], count[15]};
        end
    end
endmodule
/////////////////////////////////////////////////////////////
module ring_counter_led_shift_edge_detector(
    input clk, reset_p,
    output reg [15:0] count
    );
    
    reg [20:0] clk_div=0;
    wire posedge_clk_div_20;
   
   always @( posedge clk or posedge reset_p) begin
        if(reset_p) begin
            clk_div =0;
        end
        else begin
            clk_div = clk_div +1;
        end
   end
   
    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) begin
            count = 15'b1;
            //'clk_div = 0'다른always문에서 각각 같은변수를 바꾸면 안돼
            
        end
        else begin
            if(posedge_clk_div_20) 
            count = {count[14:0], count[15]};
        end
    end
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), 
    .cp(clk_div[20]), .p_edge(posedge_clk_div_20));
    
    
endmodule



/////////////////////////////////////////////////////////////
module edge_detector_n(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge
    );
    
    reg ff_cur, ff_old;
    
    always @ ( negedge clk or posedge reset_p)begin
        if(reset_p)begin
            ff_cur <= 0;
            ff_old <= 0;          
        end
    
        else begin
            ff_cur <= cp;       //'ff_cur = cp' 이렇게만 쓰면  blocking문 돼
            ff_old <= ff_cur;   //(앞의 코드가 실행될 동안 뒤의 코드 실행을 막아
                                //==> 'ff_cur = cp'실행될때 'ff_old <= ff_cur'실행 안돼
                                // '<=' 연산자 쓰면 병렬로 동작해
        end                     //  always 문 쓸때  웬만하면nonblocking'<=' 사용해
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule
//////////////////////////////////////////////////////////////////
module edge_detector_p(
    input clk, reset_p,
    input cp,
    output p_edge, n_edge
    );
    
    reg ff_cur, ff_old;
    
    always @ ( posedge clk or posedge reset_p)begin
        if(reset_p)begin
            ff_cur <= 0;
            ff_old <= 0;          
        end
    
        else begin
            ff_cur <= cp;       //'ff_cur = cp' 이렇게만 쓰면  blocking문 돼
            ff_old <= ff_cur;   //(앞의 코드가 실행될 동안 뒤의 코드 실행을 막아
                                //==> 'ff_cur = cp'실행될때 'ff_old <= ff_cur'실행 안돼
                                // '<=' 연산자 쓰면 병렬로 동작해
        end                     //  always 문 쓸때  웬만하면nonblocking'<=' 사용해
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule
//////////////////////////////////////////////////////////////////////
module shift_resister_SISO_n(
    input d,
    input clk, reset_p,
    output  q
    );
    
    reg [3:0] siso_reg;
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p) siso_reg <= 0;
        else begin
           siso_reg[3] <=d;
           siso_reg[2] <= siso_reg[3];
           siso_reg[1] <= siso_reg[2];
           siso_reg[0] <= siso_reg[1];
                         
    end
    end
    assign q = siso_reg[0];
endmodule
///////////////////////////////////////////ㄴ///////
module shift_resister_SIPO_n(
    input clk, reset_p,
    input d,
    input rd_en,
    output [3:0] q);
    
    
    reg[3:0] sipo_reg;
    
    always @(negedge clk or posedge reset_p) begin
        if(reset_p)begin
            sipo_reg = 0;
        end
        else begin
            sipo_reg = {d, sipo_reg[3:1]};
        end
    end
//    bufif1 (q[0], sipo_reg[0], rd_en);   
//    bufif1 (q[1], sipo_reg[1], rd_en);   
//    bufif1 (q[2], sipo_reg[2], rd_en);   
//    bufif1 (q[3], sipo_reg[3], rd_en);   
    assign q = rd_en ? sipo_reg : 4'bz;///존재이유
                                               
    //4클럭 siporeg에 입력되고 en 1되면 q출력됨
endmodule//한값만 읽어야 해서 출력 끊어놔
////레지스터는 en입력안되면 임피던스값을 출력
/////////////////////////////////////////////////////////
module shift_resister_PISO(
    input clk, reset_p,
    input [3:0] d, 
    input shift_load,
    output q
    );
    
    reg [3:0] piso_reg;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) piso_reg =0;
        else begin
           if(shift_load) piso_reg = {1'b0, piso_reg[3:1]};
           else piso_reg = d;            
        end
    end

    assign q = piso_reg[0];

endmodule
/////////////////////////////////////////////////////////
module resister_Nbit_p #(parameter N = 4)(
    input clk, reset_p,
    input [N-1:0] d,
    input wr_en, rd_en,
    output [N-1:0] q
    );
    
    reg [N-1:0] register;
    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) register =0;
        else if(wr_en) register = d;
    end
    assign q= rd_en ? register: 'bz;
endmodule    
///////////////////////////////////////////////////
module sram_8bit_1024(
    input clk,
    input wr_en, rd_en,
    input [9:0] addr,
    inout [7:0] data//출력하고싶을때 출력하면 출력, 입력
    );
    
    reg[7:0] mem [0:1023]; //앞에는 비트수 선언, 뒤에는 만들개수(배열)선언==> 8비트 메모리 1024개

    always @(posedge clk) begin
        if(wr_en)mem[addr] <= data; //디먹싱
    end

    assign data = rd_en ? mem[addr] : 'bz;
endmodule    
//////////////////////////////////////////////////////
module watch_ring_counter_watch_mode(
    input clk, reset_p, btn,
    output reg [2:0] sel
    );
    
    reg [16:0] clk_div;
    wire clk_div_16;
    always @(posedge clk) clk_div = clk_div +1;
    
    edge_detector_n ed (.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    always @(posedge btn or posedge reset_p) begin //[13]숫자변화줘
        if(reset_p) sel = 3'b110;
        else begin
         case(sel)
                3'b110: sel= 4'b101;
                3'b101: sel= 4'b011;
                3'b011: sel= 4'b110;
              
                default  sel= 4'b110;
            endcase   
         end
    end
endmodule
///////////////////////////////////////////////////////
module watch_ring_counter_shift(
    input clk, reset_p, btn,
    output reg [2:0] count
    );
    
    reg [5:0] clk_div=0;
    
    always @ (posedge clk) clk_div = clk_div +1;
    
    always @ (posedge btn, posedge reset_p) begin
        if(reset_p) count = 3'b1;
        else begin
            count = {count[1:0], count[2]};
        end
    end
endmodule
///////////////////////////////////////////////
module tri_watch_demux(
    input d,
    input [2:0] s,
    output [2:0] f);
    
    assign f= (s==3'b001) ? {2'b00, d} :        //00d
              (s==3'b010) ? {1'b0, d, 1'b0} :   //0d0
              (s==3'b100) ? {d,2'b00} :    //d00
                          {2'b00, d};          
 endmodule
