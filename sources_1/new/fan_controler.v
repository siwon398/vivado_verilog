`timescale 1ns / 1ps
//////////////////////////////////////////
module counter_pwm(
    input clk, reset_p,
    input btn_pedge,
    output reg [7:0] power,
    output reg[2:0] led
    );

    reg [1:0] cnt;
    
     always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt = 0;
            power = 0;
            led =0;
        end
        else if (btn_pedge) begin                       
            cnt = cnt + 1;
            case(cnt)
                2'b00 : begin
                    power = 7'd0;
                    led = 0;                    
                end       
                2'b01 : begin
                   led =0;
                    power = 7'd42;
                    led[0] = 1;
                end                                
                2'b10 : begin
                    led = 0;
                    power = 7'd84;
                    led[1] = 1;
                end 
                2'b11 : begin
                    led =0;
                    power = 7'd127;
                    led[2] = 1;
                end             
                default  power = 7'd0 ;
            endcase               
        end           
    end
endmodule
//////////////////////////////////////////////
module pwm_128step_fan(
    input clk, reset_p,
    input [6:0] duty,
    input [13:0]pwm_freq,
    output reg pwm_128
    );
    parameter sys_clk_freq = 100_000_000; //125_000_000  
    
    reg[26:0] cnt;
    reg pwm_freqX128;
    
    wire [26:0]temp; //100_000_000 이진수   
   
    integer cnt_sysclk;
    assign temp = sys_clk_freq/pwm_freq;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            pwm_freqX128 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:7] - 1) cnt = 0;//잘라서 버린다 == shift연산,,, 반대는 0 추가
            else cnt = cnt + 1;
                
            if(cnt <temp[26:8]) pwm_freqX128 = 0;
            else pwm_freqX128 = 1;
        end               
    end
   
    wire pwm_freqX100_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX128),.n_edge(pwm_freqX100_nedge));
    
    reg [6:0] cnt_duty;
   
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_duty = 0;
            pwm_128 = 0;            
        end
        else begin
            if(pwm_freqX100_nedge) begin
                                                   
                cnt_duty = cnt_duty + 1;
                
                if(cnt_duty < duty) pwm_128 = 1;
                else pwm_128 = 0;
            end
              
        end
    end   
endmodule   
/////////////////////////////////////////////////////////////////////////////
module loadable_downcounter_dec_60_fan(
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1,
    output reg [3:0] dec1, dec10,
    output reg dec_clk
    );
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            dec1=0;
            dec10=0;
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = 0;
            end
            else if(clk_time) begin
                if(dec1 == 0) begin  //0보다 작아질 수 없어
                     dec1 = 9;
                     if (dec10 == 0) begin
                        dec10 =5;
                        dec_clk = 1; // cooktimer모듈의 분 00에서  59초 됏을 때 1분깎이게 동기화
                     end
                     else dec10 = dec10 - 1;
                end
                else dec1 = dec1 -1;
            end
            else dec_clk =0; // 여기서 0 해서 엣지 잡을 필요 없어 (one cycle pulse라서)
        end
    end
endmodule
//////////////////////////////////////////////////
module cook_timer_fan(   //한번누르면 스타트, 한번누르면 스톱 1번버튼 초증가, 2번버튼 분증가
    input clk, reset_p,
    input btn_nedge,
    input btn_pedge,
    output [16:0] value,
    output reg [2:0]led_timer
    );
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire [3:0] cur_msec, cur_sec1, cur_sec10, cur_min1, cur_min10;
    reg cur_msec_e;
    wire load_enable;
    wire dec_clk, clk_start;
    wire [15:0]  cur_time;
   
    clock_usec usec_clk(clk_start, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk_start, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk_start, reset_p, clk_msec, clk_sec);
    
    reg timer_e;
    reg [1:0] cnt;
    reg [7:0] timer135; //[5:0]
    wire timeout_e_pedge;
    reg timeout_e;

     assign clk_start = timer_e ? clk : 0;
    
     always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt = 0;
            timer135 = 0;          
            timer_e = 0;
            cur_msec_e = 1;
        end
        else if ( btn_nedge) timer_e = 1;
        else if (btn_pedge) begin
            timer_e = 0;
            cnt = cnt + 1;
         
            case(cnt)
                2'b00 : begin
                    timer135 = 0;
                    led_timer = 0;
                    cur_msec_e = 1;
               end
                2'b01 : begin
                    led_timer = 0;
                    timer135 = 1;
                    led_timer[0] = 1;
                    cur_msec_e = 0;
                end
                2'b10 : begin
                    led_timer = 0;
                    timer135 = 3;
                    led_timer[1] = 1;
                    cur_msec_e = 0;
                end
                2'b11 : begin
                    led_timer = 0;
                    timer135 = 5;
                    led_timer[2] = 1;
                    cur_msec_e = 0;
                end                
                default  timer135 = 0 ;
             endcase
            end
        else if (timeout_e_pedge) timer_e = 0;
    end
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(timer_e), .p_edge(load_enable));
    

    loadable_downcounter_dec_60_fan cur_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(load_enable),
                .dec1(cur_sec1), .dec10(cur_sec10), .dec_clk(dec_clk));
    loadable_downcounter_dec_60_fan cur_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(load_enable),
                 .set_value1(timer135), .dec1(cur_min1), .dec10(0));
    
    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            timeout_e = 0;
        end
        else begin
            if (timer_e && clk_msec && cur_time == 0) begin
                timeout_e = 1;
            end
            else begin
                timeout_e =0;
            end
        end
    end
    
    edge_detector_n ed_timeout_e(.clk(clk), .reset_p(reset_p), .cp(timeout_e),  .p_edge(timeout_e_pedge));
   
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1, cur_msec_e};
    assign value = cur_time;
    reg [16:0] clk_div =0;
    always @(posedge clk) clk_div = clk_div +1;
endmodule
///////////////////////////////////////////////////////////////////

