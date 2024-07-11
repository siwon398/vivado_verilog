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
        

/////////////////////

////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////
module pwm_100pc(
    input clk, reset_p,
    input [6:0] duty,
    input [13:0]pwm_freq,
    output reg pwm_100pc
    );
    parameter sys_clk_freq = 100_000_000; //125_000_000  //pwm_freq 나누기 sys_clk_freq 결과값의 반은 1, 반은 0
    
    reg[26:0] cnt;
    reg pwm_freqX100;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            pwm_freqX100 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= sys_clk_freq / (pwm_freq *100) - 1) cnt = 0;
            else cnt = cnt + 1;
                
            if(cnt < sys_clk_freq / pwm_freq / 100/2) pwm_freqX100 = 0;
            else pwm_freqX100 = 1;
        end              
    end
   
    wire pwm_freqX100_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX100),.n_edge(pwm_freqX100_nedge));
    
    reg [6:0] cnt_duty;
   
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_duty = 0;
            pwm_100pc = 0;            
        end
        else begin
            if(pwm_freqX100_nedge) begin
                if(cnt_duty >= 99) cnt_duty = 0;    //100개 카운터가 내가 설정한 듀티값보다 적으면 0 많으면 1
                else cnt_duty = cnt_duty + 1;
                
                if(cnt_duty < duty) pwm_100pc = 1;
                else pwm_100pc = 0;
            end
            else begin
            
            end        
        end
    end   
endmodule 
//////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////
module pwm_512step(
    input clk, reset_p,
    input [8:0] duty, 
    input [13:0]pwm_freq,
    output reg pwm_512
    );
    parameter sys_clk_freq = 100_000_000; //125_000_000  
    
    reg[26:0] cnt;
    reg pwm_freqX512;
    
    wire [31:0]temp; //100_000_000 이진수   
   
    integer cnt_sysclk;
    assign temp = sys_clk_freq/pwm_freq;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            pwm_freqX512 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[27:9] - 1) cnt = 0;//잘라서 버린다 == shift연산,,, 반대는 0 추가
            else cnt = cnt + 1;
                
            if(cnt <temp[27:10]) pwm_freqX512 = 0;
            else pwm_freqX512 = 1;
        end               
    end
   
    wire pwm_freqX512_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX512),.n_edge(pwm_freqX512_nedge));
    
    reg [8:0] cnt_duty;
   
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_duty = 0;
            pwm_512 = 0;            
        end
        else begin
            if(pwm_freqX512_nedge) begin
                                                   
                cnt_duty = cnt_duty + 1;
                
                if(cnt_duty < duty) pwm_512 = 1;
                else pwm_512 = 0;
            end                   
        end
    end   
endmodule   
///////////////////////////////////////////////////

////////////////////////////////////////////////


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
