`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module clock_usec(
    input clk, reset_p,
    output clk_usec
    );
    
    reg [7:0] cnt_sysclk;   //8ns
    wire cp_usec;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) cnt_sysclk =0;
        else if (cnt_sysclk >=99) cnt_sysclk = 0;      //cnt_sysclk[0]만 이용하는데 1usec범위를 지정하면서 124로 제한하고 그때 cnt_sysclk[6]생길수밖에 없어
        else cnt_sysclk = cnt_sysclk +1;
    end
    
    assign cp_usec = (cnt_sysclk < 50) ? 0 : 1;
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(cp_usec), .n_edge(clk_usec));
    
  
endmodule
///////////////////////////////////////////////////////////////////////

module clock_div_1000(
    input clk, reset_p,
    input clk_source,
    output clk_div_1000
    );
    
    reg [9:0] cnt_clk_source;//1000개
    reg cp_div_1000;
    
//    always @(posedge clk or posedge reset_p) begin//여기서
//        if(reset_p)cnt_clk_source =0;
//        else if(clk_source) begin
//            if(cnt_clk_source > 999) cnt_clk_source =0;
//            else cnt_clk_source = cnt_clk_source +1;
//        end
//    end
//    assign cp_div_1000 = cnt_clk_source >= 499 ? 1 : 0;//여기까지   //500msec동안 0.다음 500msec동안1 //300해도 첨 300은 0 나머지 700은 1
    
     always @(posedge clk or posedge reset_p) begin//여기서
        if(reset_p) begin
            cnt_clk_source =0;
            cp_div_1000 =0;
        end
        else if(clk_source) begin
            if(cnt_clk_source >= 499) begin 
            cnt_clk_source =0;
            cp_div_1000=~cp_div_1000;
        end     
        else cnt_clk_source = cnt_clk_source +1;
        end
    end//여기까지
    
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(cp_div_1000), .n_edge(clk_div_1000));
    
    endmodule
    //////////////////////////////////////////////
    
module clock_min(    
    input clk, reset_p,
    input clk_sec,
    output clk_min
    );
    
    reg [8:0] cnt_sec;//1000개
    reg cp_min;

     always @(posedge clk or posedge reset_p) begin//여기서
        if(reset_p) begin
            cnt_sec =0;
            cp_min =0;
        end
        else if(clk_sec) begin
            if(cnt_sec >= 29) begin 
            cnt_sec =0;
            cp_min=~cp_min;
        end     
        else cnt_sec = cnt_sec +1;
        end
    end//여기까지
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(cp_min), .n_edge(clk_min));
    
    endmodule
    
//////////////////////////////////////////////////////////////////////////////////
module counter_dec_60(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            dec1=0;
            dec10=0;
            
        end
        else begin
            if(clk_time) begin
                if(dec1 >=9) begin
                     dec1 = 0;
                     if (dec10>=5) dec10 =0;
                     else dec10 = dec10 + 1;
                end     
                else dec1 = dec1 +1;
            end            
        end
    end
endmodule

////////////////////////////////////////////////////////////////////////////////
module loadable_counter_dec_60(
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1, set_value10,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            dec1=0;
            dec10=0;
            
        end
        else begin
            if(load_enable)begin
                dec1 = set_value1;
                dec10 = set_value10;
            end
            else if(clk_time) begin
                if(dec1 >=9) begin  //10되면 1의자리 0
                     dec1 = 0;
                     if (dec10>=5) dec10 =0;    //59분 후에 00분
                     else dec10 = dec10 + 1;    //6전까지 1씩증가
                end     
                else dec1 = dec1 +1;
            end            
        end
    end
endmodule
/////////////////////////////////////////////////////
module loadable_watch(
    input clk, reset_p,
    input [2:0] btn_pedge,
    output [15:0] value
    );
    
    wire clk_usec, clk_msec, clk_sec, clk_min;
    wire sec_edge, min_edge;
    wire [3:0] sec1, sec10, min1, min10;
    wire [15:0] set_mode;
    wire cur_time_load_en, set_time_load_en;
    wire [3:0] cur_sec1, cur_sec10, set_sec1, set_sec10;
    wire [3:0] cur_min1, cur_min10, set_min1, set_min10;
    wire [15:0] cur_time, set_time;
    
    clock_usec usec_clk(clk, reset_p, clk_usec); 
    clock_div_1000 msec_clk(clk, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk, reset_p, sec_edge, clk_min);
 
    loadable_counter_dec_60 cur_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(cur_time_load_en), .set_value1(set_sec1), .set_value10(set_sec10),
    .dec1(cur_sec1), .dec10(cur_sec10)); // 현재시간 초카운터
    loadable_counter_dec_60 cur_time_min(.clk(clk), .reset_p(reset_p), .clk_time(clk_min), .load_enable(cur_time_load_en), .set_value1(set_min1), .set_value10(set_min10),
    .dec1(cur_min1), .dec10(cur_min10)); // 현재시간 분카운터
    loadable_counter_dec_60 set_time_sec(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[1]), .load_enable(set_time_load_en), .set_value1(cur_sec1), .set_value10(cur_sec10),
    .dec1(set_sec1), .dec10(set_sec10)); // 세팅시간 초카운터
    loadable_counter_dec_60 set_time_min(.clk(clk), .reset_p(reset_p), .clk_time(btn_pedge[2]), .load_enable(set_time_load_en), .set_value1(cur_min1), .set_value10(cur_min10),
    .dec1(set_min1), .dec10(set_min10)); // 세팅시간 분카운터
   
//  1                                                                                                                          assign value = set_mode ? {set_min10, set_min1, set_sec10, set_sec1} : {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
    assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
    assign value = set_mode ? set_time : cur_time;
   
    T_flip_flop_p tff_setmode(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(set_mode));
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(set_mode), .n_edge(cur_time_load_en), .p_edge(set_time_load_en));
    
    assign sec_edge = set_mode ? btn_pedge[1] : clk_sec;
    assign min_edge = set_mode ? btn_pedge[2] : clk_min;
    
endmodule

//////////////////////////////////////////////////////////////////////////////////////////////
module counter_dec_100(
    input clk, reset_p,
    input clk_time,
    output reg [3:0] dec1, dec10
    );
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            dec1=0;
            dec10=0;
            
        end
        else begin
            if(clk_time) begin
                if(dec1 >=9) begin
                     dec1 = 0;
                     if (dec10>=9) dec10 =0;
                     else dec10 = dec10 + 1;
                end     
                else dec1 = dec1 +1;
            end            
        end
    end
endmodule

//////////////////////////////////////////////////////////////////////////////////
module clock_div_10(
    input clk, reset_p,
    input clk_source,
    output clk_div_10
    );
    
    reg [14:0] cnt_clk_source;//1000개
    reg cp_div_10;
    
//    always @(posedge clk or posedge reset_p) begin//여기서
//        if(reset_p)cnt_clk_source =0;
//        else if(clk_source) begin
//            if(cnt_clk_source > 999) cnt_clk_source =0;
//            else cnt_clk_source = cnt_clk_source +1;
//        end
//    end
//    assign cp_div_1000 = cnt_clk_source >= 499 ? 1 : 0;//여기까지   //500msec동안 0.다음 500msec동안1 //300해도 첨 300은 0 나머지 700은 1
    
     always @(posedge clk or posedge reset_p) begin//여기서
        if(reset_p) begin
            cnt_clk_source =0;
            cp_div_10 =0;
        end
        else if(clk_source) begin
            if(cnt_clk_source > 4) begin 
            cnt_clk_source =0;
            cp_div_10=~cp_div_10;
        end     
        else cnt_clk_source = cnt_clk_source +1;
        end
    end//여기까지
    
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(cp_div_10), .n_edge(clk_div_10));
    
    endmodule
    //////////////////////////////////////////////////////////////////////////////////////////////////
    module stop_watch_csec( // 카운터 값이 덮어써지는 시계
    input clk, reset_p,
    input [2:0]btn_pedge,
    output [15:0] value
);
   wire clk_usec, clk_msec, clk_csec, clk_sec, clk_min;

   wire start_stop;
   wire clk_start;
   wire [3:0] sec1, sec10,msec1,msec10,csec1,csec10;
   wire lap_swatch, lap_load;
   reg [15:0] lap;
   wire [15:0] cur_time;
           
    clock_usec usec_clk(clk_start, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk_start, reset_p, clk_usec, clk_msec);
    clock_div_10 csec_clk(clk_start, reset_p, clk_msec, clk_csec);
    clock_div_1000 sec_clk(clk_start, reset_p, clk_msec, clk_sec);
    clock_min min_clk(clk_start, reset_p, clk_sec, clk_min);
    
     T_flip_flop_p tff_start(.clk(clk), .reset_p(reset_p), .t(btn_pedge[0]), .q(start_stop));
     
     assign clk_start = start_stop ? clk : 0;
     
    counter_dec_60 counter_sec(clk, reset_p, clk_sec, sec1, sec10);
    counter_dec_100 counter_csec(clk, reset_p, clk_csec, csec1, csec10);
            
    T_flip_flop_p tff_lap(.clk(clk), .reset_p(reset_p), .t(btn_pedge[1]), .q(lap_swatch));
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(lap_swatch),  .p_edge(lap_load));
         
     always @(posedge clk or posedge reset_p) begin
        if(reset_p)lap = 0;
        else if(lap_load) lap = {sec10, sec1,csec10,csec1};        
     end
     
     assign value = lap_swatch ? lap : {sec10, sec1,csec10,csec1};
     
     fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));
endmodule

    /////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////
module loadable_downcounter_dec_60(
    input clk, reset_p,
    input clk_time,
    input load_enable,
    input [3:0] set_value1, set_value10,
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
                dec10 = set_value10;
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
///////////////////////////////////////////////////
module cook_timer(   //한번누르면 스타트, 한번누르면 스톱 1번버튼 초증가, 2번버튼 분증가
    input clk, reset_p,
    input [3:0] btn_pedge,
    output [15:0] value,
    output [5:0]led,
    output buzz_clk
    );
         //00초에서 59초될때 클럭 내보내-->loadable_downcounter_dec_60 모듈에서 elseif의 10의자리 0일때 5되는 부분에서 가능       
   wire clk_usec, clk_msec, clk_sec, clk_min;
   wire clk_start;  
   
   reg alarm;  
   wire btn_start, inc_sec, inc_min, alarm_off;
   wire [3:0] set_sec1, set_sec10, set_min1, set_min10;
   wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10;
   wire load_enable, dec_clk,clk_start;
   reg start_stop;
   wire [15:0]  cur_time, set_time;
   wire timeout_pedge;
   reg time_out;                                //cur time 이 0이 됏을때 timeout을 1로 하니까 스타트 버튼 눌럿는데 
                                                //1이 되는데 엣지가 나오는건 한클럭 뒤,,그 엣지로 티플립이 엣지발생하는건 또 한클럭 뒤  
   assign {alarm_off,inc_min,inc_sec, btn_start} = btn_pedge;
     
   assign led[5] = start_stop;
   assign led[4] = time_out;
   assign led[0] = alarm;
   
   assign clk_start = start_stop ? clk : 0;
           
    clock_usec usec_clk(clk_start, reset_p, clk_usec);
    clock_div_1000 msec_clk(clk_start, reset_p, clk_usec, clk_msec);
    clock_div_1000 sec_clk(clk_start, reset_p, clk_msec, clk_sec);
    
    counter_dec_60 set_sec(clk, reset_p,  inc_sec, set_sec1, set_sec10);
    counter_dec_60 set_min(clk, reset_p,  inc_min, set_min1, set_min10);
     
    loadable_downcounter_dec_60 cur_sec(.clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(load_enable), 
                .set_value1(set_sec1), .set_value10(set_sec10),.dec1(cur_sec1), .dec10(cur_sec10), .dec_clk(dec_clk));                            
    loadable_downcounter_dec_60 cur_min(.clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(load_enable), 
                .set_value1(set_min1), .set_value10(set_min10),.dec1(cur_min1), .dec10(cur_min10)); 
                //wire에 두가지 값을 연결하면 multiple driven error나, reg는 error안나==racing 상태

     edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(time_out),  .p_edge(timeout_pedge));
        
//    T_flip_flop_p tff_start(.clk(clk), .reset_p(reset_p), .t(btn_start), .q(start_stop));
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) start_stop = 0;
        else begin
            if(btn_start) start_stop = ~start_stop;//버튼 누르면 스타트 스탑 1되고, 그다음에  들어왔을 때                            
            else if(timeout_pedge) start_stop = 0;//아직         
        end
    end
    
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(start_stop),  .p_edge(load_enable));

    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) time_out = 0;
        else begin
            if (start_stop && clk_msec && cur_time == 0)time_out=1;
            else time_out = 0;
        end
    end
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            alarm = 0;
        end
        else begin
            if(timeout_pedge)alarm = 1; 
            else if(alarm && alarm_off) alarm = 0;
        end
    end

   assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
   assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
   assign value = start_stop ? cur_time: set_time;
    
    reg [16:0] clk_div =0;
    always @(posedge clk) clk_div = clk_div +1;
    assign buzz_clk = alarm ? clk_div[12] : 0;
    
endmodule
    /////////////////////////////////////////////////////////////
  
    //////////////////////////////////////////////////////////////
    
  
    /////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
module multi_purpose_watch_1(
    input clk, reset_p,
    input [4:0] btn,
    output [3:0] com,
    output[7:0] seg_7,
    output buzz_clk
    );
    
    parameter watch_mode = 3'b001;
    parameter stop_watch_mode = 3'b010;
    parameter cook_timer_mode = 3'b100;
    
    wire [2:0] watch_btn, stopw_btn;
    wire [3:0] cook_btn;
    wire [15:0] value, watch_value, stop_watch_value, cook_timer_value;
    reg [2:0] mode;
    wire btn_mode;
    wire [3:0] btn_pedge;
    
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[3]), .btn_pe(btn_pedge[3]));
    button_cntr btn_cntr4(.clk(clk), .reset_p(reset_p), .btn(btn[4]), .btn_pe(btn_mode));
        
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)mode = watch_mode;
        else if(btn_mode)begin
            case(mode)
                watch_mode : mode = stop_watch_mode;
                stop_watch_mode : mode = cook_timer_mode;
                cook_timer_mode : mode = watch_mode;
                default : mode = watch_mode;
            endcase    
        end
    end    
    
    assign  {cook_btn, stopw_btn, watch_btn} = (mode == watch_mode) ? {7'b0 , btn_pedge[2:0]} :            //순서중요
                                                (mode == stop_watch_mode) ? {4'b0,btn_pedge[2:0], 3'b0} :
                                                {btn_pedge[3:0], 6'b0};  
    
    loadable_watch watch(clk, reset_p, watch_btn, watch_value);
    stop_watch_csec stop_watch(clk, reset_p, stopw_btn, stop_watch_value);
    cook_timer cook(clk, reset_p, cook_btn, cook_timer_value, led, buzz_clk);
    
      fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));

   assign value = (mode == cook_timer_mode) ?  cook_timer_value : 
                  (mode == stop_watch_mode) ?  stop_watch_value : 
                  watch_value;
   
endmodule
///////////////////////////////////////////////////////////


////////////////////////////////////////////////////////////
