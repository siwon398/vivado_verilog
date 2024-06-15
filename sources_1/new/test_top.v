`timescale 1ns / 1ps
///////////////////
module button_test_top(
    input clk, reset_p,
    input btnU,
    output [7:0] seg_7,
    output [3:0] com);    
 
    reg [15:0] btn_counter;
    reg [3:0] value;
    wire btnU_pedge;
    reg [16:0] clk_div=0;//원래는 =0 없어
    
    always @ (posedge clk)      clk_div = clk_div +1;
     
    wire clk_div_16;                                    //16번 비트가 대충1ms
   
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
     
    reg debounced_btn;
    
    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) debounced_btn=0;
        else if (clk_div_16) debounced_btn = btnU;
    end   
   
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .p_edge(btnU_pedge));   
   
    always @( posedge clk, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            if(btnU_pedge) btn_counter = btn_counter + 1;
        end
    end
  
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));//분주기 속도 빨리하면 결과 안나와_이유는?    

    always @(posedge clk) begin//굳이 링카운터 결과  com을 가져와 쓰는 이유는? 안쓰고 못하냐-->링카운터 써야 데이터 업뎃되나?
        case(com)
            4'b0111: value = btn_counter[15:12];     4'b1011: value = btn_counter[11:8];
            4'b1101: value = btn_counter[7:4];       4'b1110: value = btn_counter[3:0];
        endcase
    end    
  
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7));   
  
    endmodule
    ///////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
module button_test_top_noed(
    input clk, reset_p,
    input btnU,
    output [7:0] seg_7,
    output [3:0] com);
    
    reg [15:0] btn_counter;
    reg [3:0] value;
  

    
    always @( posedge btnU, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            btn_counter = btn_counter + 1;
        end
    end

    ring_counter_fnd rc(
    .clk(clk), 
    .reset_p(reset_p), 
    .com(com)
    );//분주기 속도 빨리하면 결과 안나와_이유는?
    
    always @(posedge clk) begin
        case(com)
            4'b0111: value = btn_counter[15:12];
            4'b1011: value = btn_counter[11:8];
            4'b1101: value = btn_counter[7:4];
            4'b1110: value = btn_counter[3:0];
        endcase
    end
    
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7));
    
    endmodule//chattering 이해, 왜 계속누르면 증가 안함?

//////////////////////////////////////////////////////////////////////////////////
  module led_bar_top(
        input clk, reset_p,
        output [7:0]led_bar);
        
        reg [30:0] clk_div;
        always @(posedge clk) clk_div = clk_div +1;
        
        assign led_bar = ~clk_div[28:21];
        
    endmodule
/////////////////////////////
module button_ledbar_top(
    input clk, reset_p,
    input [1:0]btn,
    output [7:0] led_bar
   );    
 
    reg [7:0] btn_counter;
    reg [3:0] value;
    wire btnU_pedge;
    reg [16:0] clk_div;//원래는 =0 없어
    
    always @ (posedge clk)      clk_div = clk_div +1;
     
    wire clk_div_16;                                    //16번 비트가 대충1ms
   
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
     
    reg debounced_btn;
    
    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) debounced_btn=0;
        else if (clk_div_16) debounced_btn = btn;
    end   
   
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .p_edge(btnU_pedge));   
   
    always @( posedge clk, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            if(btnU_pedge) btn_counter = btn_counter - 1;
        end
    end
   
    
    assign led_bar = ~btn_counter; 


    endmodule    
 //////////////////////////////////////////////
    module button_test_top_bread2(
    input clk, reset_p,
    input [3:0]btn,
    output [7:0] seg_7,
    output [3:0] com);    
 
    reg [15:0] btn_counter;
    reg [3:0] value;
    wire [3:0] btnU_pedge;

    
//   button_cntr btnU_cntr1(.clk(clk), .reset_p(reset_p),
//.btn(btn[0]), .btn_pe(btnU_pedge[0]));
//   button_cntr btnU_cntr2(.clk(clk), .reset_p(reset_p),
//.btn(btn[1]), .btn_pe(btnU_pedge[1]));
//   button_cntr btnU_cntr3(.clk(clk), .reset_p(reset_p),
//.btn(btn[2]), .btn_pe(btnU_pedge[2]));
//   button_cntr btnU_cntr4(.clk(clk), .reset_p(reset_p),
//.btn(btn[3]), .btn_pe(btnU_pedge[3]));
    
    genvar i;
    generate
        for (i=0; i<4; i=i+1) begin: btn_cntr   //인스턴스 이름
            button_cntr btnU_cntr1(.clk(clk), .reset_p(reset_p),
.btn(btn[i]), .btn_pe(btnU_pedge[i]));
       
        end
    endgenerate
    
    always @( posedge clk, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
             else if(btnU_pedge[1])btn_counter = btn_counter - 1;
             else if(btnU_pedge[2])btn_counter = {btn_counter[14:0], btn_counter[15]};
             else if(btnU_pedge[3])btn_counter = {btn_counter[0], btn_counter[15:1]};
        end
    end
  
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(btn_counter), .seg_7_ca(seg_7), .com(com));
  
    endmodule
///////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////
    module button_test_top_bread(
    input clk, reset_p,
    input [1:0]btn,
    output [7:0] seg_7,
    output [3:0] com);    
 
    reg [15:0] btn_counter;
    reg [3:0] value;
    wire [1:0]btnU_pedge;
    reg [16:0] clk_div=0;//원래는 =0 없어
    
    always @ (posedge clk)      clk_div = clk_div +1;
     
    wire clk_div_16;                                    //16번 비트가 대충1ms
   
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
     
    reg [1:0]debounced_btn;
    
    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) debounced_btn=0;
        else if (clk_div_16) debounced_btn = btn;
    end   
   
   edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[0]), .p_edge(btnU_pedge[0]));   
   edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btnU_pedge[1]));
   
    always @( posedge clk, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
             else if(btnU_pedge[1])btn_counter = btn_counter - 1;
        end
    end
  
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));//분주기 속도 빨리하면 결과 안나와_이유는?    

    always @(posedge clk) begin
        case(com)
            4'b0111: value = btn_counter[15:12];     4'b1011: value = btn_counter[11:8];
            4'b1101: value = btn_counter[7:4];       4'b1110: value = btn_counter[3:0];
        endcase
    end    
    wire [7:0] seg_7_bar;
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7_bar));   
    assign  seg_7= ~seg_7_bar;
    endmodule
    ///////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////
module button_ledbar_top_down_seg(
    input clk, reset_p,
    input btn,
    output [7:0] seg_7
   );    
 
    reg [7:0] btn_counter;
    reg [3:0] value;
    wire [1:0]btnU_pedge;
    reg [16:0] clk_div;//원래는 =0 없어
    
    always @ (posedge clk)      clk_div = clk_div +1;
     
    wire clk_div_16;                                    //16번 비트가 대충1ms
   
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
     
    reg [1:0]debounced_btn;
    
    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) debounced_btn=0;
        else if (clk_div_16) debounced_btn = btn;

    end   
   
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[0]), .p_edge(btnU_pedge[0]));   
    edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btnU_pedge[1]));
   
    always @( posedge clk, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
            else if(btnU_pedge[1])btn_counter = btn_counter - 1;
        end
    end
    wire [7:0]seg_7_bar;

    decoder_7seg fnd (.hex_value(btn_counter), .seg_7(seg_7_bar));   
    assign seg_7= ~seg_7_bar;
endmodule    
 

    ///////////////////////////////////////////////////////////////////////////////
module button_ledbar_top_down(
    input clk, reset_p,
    input [1:0]btn,
    output [7:0] led_bar
   );    
 
    reg [7:0] btn_counter;
    reg [3:0] value;
    wire [1:0]btnU_pedge;
    reg [16:0] clk_div;//원래는 =0 없어
    
    always @ (posedge clk)      clk_div = clk_div +1;
     
    wire clk_div_16;                                    //16번 비트가 대충1ms
   
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
     
    reg [1:0]debounced_btn;
    
    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) debounced_btn=0;
        else if (clk_div_16) debounced_btn = btn;

    end   
   
    edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[0]), .p_edge(btnU_pedge[0]));   
    edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btnU_pedge[1]));
   
    always @( posedge clk, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
            else if(btnU_pedge[1])btn_counter = btn_counter - 1;
        end
    end
   
    
    assign led_bar = ~btn_counter; 

endmodule    
//////////////////////////////////////////////////////////////////////////////
module keypad_test_top(
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [7:0] seg_7,
    output [3:0] com);
    
    wire [3:0] key_value;
    key_pad_cntr key_pad(.clk(clk), .reset_p(reset_p),
            .row(row), .col(col), .key_value(key_value));
    
    wire key_valid_pe;        
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(key_valid), .p_edge(key_valid_pe));
    
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({12'b0, key_value}),
            .seg_7_ca(seg_7), .com(com));
            
            
endmodule
/////////////////////////////////////////////
module keypad_test_counter_mine(
    input clk, reset_p,
    input [3:0]btn,
    output [3:0] com,
    output [7:0] seg_7);    
 
    reg [15:0] btn_counter;
    reg [3:0] value;
    wire [1:0]btnU_pedge;
    reg [16:0] clk_div;//원래는 =0 없어
    
    always @ (posedge clk)      clk_div = clk_div +1;
     
    wire clk_div_16;                                    //16번 비트가 대충1ms
   
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
     
    reg [3:0]debounced_btn;
    
    always @ (posedge clk, posedge reset_p) begin
        if(reset_p) debounced_btn=0;
        else if (clk_div_16) debounced_btn = btn;
    end   
   
   edge_detector_n ed2(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[100]), .p_edge(btnU_pedge[0]));   //1눌럿을때
   edge_detector_n ed3(.clk(clk), .reset_p(reset_p), .cp(debounced_btn[1]), .p_edge(btnU_pedge[1]));    //2눌럿을때
   
    always @( posedge clk, posedge reset_p) begin
        if(reset_p)btn_counter= 0;
        else begin
            if(btnU_pedge[0]) btn_counter = btn_counter + 1;
             else if(btnU_pedge[1])btn_counter = btn_counter - 1;
        end
    end
  
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));  

    always @(posedge clk) begin
        case(com)
            4'b0111: value = btn_counter[15:12];     4'b1011: value = btn_counter[11:8];
            4'b1101: value = btn_counter[7:4];       4'b1110: value = btn_counter[3:0];
        endcase
    end    
      wire [7:0] seg_7_bar;
    decoder_7seg fnd (.hex_value(value), .seg_7(seg_7_bar));   
    assign  seg_7= ~seg_7_bar;
    endmodule
    //////////////////////////////////////////////////////
    module keypad_test_counter_top_mine(
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [7:0] seg_7,
    output [3:0] com);
    
    wire [3:0] key_value;
    key_pad_cntr key_pad(.clk(clk), .reset_p(reset_p),
            .row(row), .col(col), .key_value(key_value));
            
     keypad_test_counter_mine kc( .clk(clk), .reset_p(reset_p), .btn(key_value), .com(com), .seg_7(seg_7));       
    
            
endmodule
//////////////////////////////////////
module keypad_test_top_counter(
    input clk, reset_p,
    input [3:0] row,
    output [3:0] col,
    output [7:0] seg_7,
    output [3:0] com);
    
    wire [3:0] key_value;
    keypad_cntr_FSM key_pad(.clk(clk), .reset_p(reset_p),
            .row(row), .col(col), .key_value(key_value), .key_valid(key_valid));
    
    wire key_valid_pe;        
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(key_valid), .p_edge(key_valid_pe));
    
    reg [15:0] key_counter;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) key_counter =0;
        else if(key_valid_pe)begin
            if(key_value==1) key_counter = key_counter +1;
            else if(key_value==2) key_counter = key_counter -1;
        end
    end
    
            
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value({key_counter}),
            .seg_7_ca(seg_7), .com(com));
            
            
endmodule
//////////////////////////////////////////////////////////////////

module keypad_cntr_FSM(
    input clk, reset_p,
    input [3:0] row,
    output reg[3:0] col,
    output reg [3:0] key_value,
    output reg key_valid);
       
    parameter SCAN_0 =      5'b00001;//  이이후에 값 못바꿔=  상수로 정의함
    parameter SCAN_1 =      5'b00010;
    parameter SCAN_2 =      5'b00100;
    parameter SCAN_3 =      5'b01000;
    parameter KEY_PROCESS = 5'b10000;
    
    reg [2:0] state, next_state;

    reg [19:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    wire clk_8msec;
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]),
            .p_edge(clk_8msec));
            
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)state = SCAN_0;
        else if(clk_8msec) state = next_state;
    end
        
    always @ * begin
        case(state)
            SCAN_0: begin
                if(row==0) next_state = SCAN_1;
                else next_state = KEY_PROCESS;
            end
             SCAN_1: begin
                if(row==0) next_state = SCAN_2;
                else next_state = KEY_PROCESS;
            end
             SCAN_2: begin
                if(row==0) next_state = SCAN_3;
                else next_state = KEY_PROCESS;
            end
             SCAN_3: begin
                if(row==0) next_state = SCAN_0;
                else next_state = KEY_PROCESS;
            end
             KEY_PROCESS: begin
                if(row!=0) next_state = KEY_PROCESS;
                else next_state = SCAN_0;
            end
        endcase
    end
    
   
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            key_value =0;
            key_valid =0;
            col = 4'b0001;
        end
        else begin
            case(state)
                SCAN_0:begin col =4'b0001; key_valid = 0; end
                SCAN_1:begin col =4'b0010; key_valid = 0; end
                SCAN_2:begin col =4'b0100; key_valid = 0; end
                SCAN_3:begin col =4'b1000; key_valid = 0; end
                KEY_PROCESS:  begin
                    key_valid = 1;
                     case({col, row})
                        8'b0001_0001: key_value = 4'h7;     //0
                        8'b0001_0010: key_value = 4'h4;     //1
                        8'b0001_0100: key_value = 4'h1;     //2
                        8'b0001_1000: key_value = 4'hC;     //3
                        8'b0010_0001: key_value = 4'h8;     //4
                        8'b0010_0010: key_value = 4'h5;     //5
                        8'b0010_0100: key_value = 4'h2;     //6
                        8'b0010_1000: key_value = 4'h0;     //7
                        8'b0100_0001: key_value = 4'h9;     //8
                        8'b0100_0010: key_value = 4'h6;     //9
                        8'b0100_0100: key_value = 4'h3;     //a
                        8'b0100_1000: key_value = 4'hF;     //b
                        8'b1000_0001: key_value = 4'hA;     //c
                        8'b1000_0010: key_value = 4'hB;     //d
                        8'b1000_0100: key_value = 4'hE;     //e
                        8'b1000_1000: key_value = 4'hD;     //f                    
                    endcase
                end
           endcase
        end
    end    
endmodule
/////////////////////////////////////////////////////////////////////
module keypad_cntr_FSM_nolatch(
    input clk, reset_p,
    input [3:0] row,
    output reg[3:0] col,
    output reg [3:0] key_value,
    output reg key_valid);
       
    parameter SCAN_0 =      5'b00001;//  이이후에 값 못바꿔=  상수로 정의함
    parameter SCAN_1 =      5'b00010;
    parameter SCAN_2 =      5'b00100;
    parameter SCAN_3 =      5'b01000;
    parameter KEY_PROCESS = 5'b10000;
    
    reg [2:0] state, next_state;
    
    always @ * begin
        case(state)
            SCAN_0: begin
                if(row==0) next_state = SCAN_1;
                else next_state = KEY_PROCESS;
            end
             SCAN_1: begin
                if(row==0) next_state = SCAN_2;
                else next_state = KEY_PROCESS;
            end
             SCAN_2: begin
                if(row==0) next_state = SCAN_3;
                else next_state = KEY_PROCESS;
            end
             SCAN_3: begin
                if(row==0) next_state = SCAN_0;
                else next_state = KEY_PROCESS;
            end
             KEY_PROCESS: begin
                if(row!=0) next_state = KEY_PROCESS;
                else next_state = SCAN_0;
            end
            default : next_state =SCAN_0;
        endcase
    end
    
    reg [19:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    wire clk_8msec;
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[19]),
            .p_edge(clk_8msec));
            
    always @(posedge clk or posedge reset_p) begin
        if(reset_p)state = SCAN_0;
        else if(clk_8msec) state = next_state;
    end
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            key_value =0;
            key_valid =0;
            col = 4'b0001;
        end
        else begin
            case(state)
                SCAN_0:begin col =4'b0001; key_valid = 0; end
                SCAN_1:begin col =4'b0010; key_valid = 0; end
                SCAN_2:begin col =4'b0100; key_valid = 0; end
                SCAN_3:begin col =4'b1000; key_valid = 0; end
                KEY_PROCESS:  begin
                    key_valid = 1;
                     case({col, row})
                        8'b0001_0001: key_value = 4'h7;     //0
                        8'b0001_0010: key_value = 4'h4;     //1
                        8'b0001_0100: key_value = 4'h1;     //2
                        8'b0001_1000: key_value = 4'hC;     //3
                        8'b0010_0001: key_value = 4'h8;     //4
                        8'b0010_0010: key_value = 4'h5;     //5
                        8'b0010_0100: key_value = 4'h2;     //6
                        8'b0010_1000: key_value = 4'h0;     //7
                        8'b0100_0001: key_value = 4'h9;     //8
                        8'b0100_0010: key_value = 4'h6;     //9
                        8'b0100_0100: key_value = 4'h3;     //a
                        8'b0100_1000: key_value = 4'hF;     //b
                        8'b1000_0001: key_value = 4'hA;     //c
                        8'b1000_0010: key_value = 4'hB;     //d
                        8'b1000_0100: key_value = 4'hE;     //e
                        8'b1000_1000: key_value = 4'hD;     //f                    
                    endcase
                end
           endcase
        end
    end    
endmodule
//////////////////////////////////////////////////


module dht11_top(
    input clk, reset_p,
    inout dht11_data,
    output [3:0] com,
    output [7:0] seg_7, led_bar
    );
    
    wire [7:0] humidity, temperature;
    dht11 dht(clk, reset_p, dht11_data, humidity, temperature, led_bar);
    wire [15:0] bcd_humi, bcd_tmpr;
    bin_to_dec humi(.bin({4'b0000,humidity}), .bcd(bcd_humi));
    bin_to_dec tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr));
    
    wire [15:0] value;
    assign value = {bcd_humi[7:0], bcd_tmpr[7:0]};
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));
    
endmodule
//////////////////////////////////////////////////////////////////////////////////
module sonic_top(
    input clk, reset_p,
    input echo,
    output trig,
    output [3:0] com,
    output [7:0] seg_7, 
    output [2:0] led_bar
    );
     
    wire [11:0]distance;
    wire [15:0] bcd_echo;
    sonic sonic(.clk(clk), .reset_p(reset_p), .echo(echo), .trig(trig), .led_bar(led_bar), .distance_out(distance));
   
    bin_to_dec echo_1(.bin({4'b0000,distance}), .bcd(bcd_echo));
    
     fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_echo), .seg_7_ca(seg_7), .com(com));
    
endmodule
/////////////////////////////////////////////////////////////////
module ultra_sonic_prof_5top(
    input clk, reset_p,
    input echo,
    output trigger,
    output [3:0] com,
    output [7:0] seg_7,
    output [3:0] led_bar
);
    wire [11:0] distance;
    ultra_sonic_prof ult(clk, reset_p, echo, trigger, distance, led_bar);

    wire [15:0] bcd_dist;
    bin_to_dec dist(.bin(distance), .bcd(bcd_dist));

    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_dist), .seg_7_an(seg_7), .com(com));

endmodule
/////////////////////////////////////////////////////////////////////////////////////////////
module led_pwm_top(
    input clk, reset_p,
    output [3:0]led_pwm
    );
    
    reg [27:0] clk_div;
    always @ (posedge clk) clk_div = clk_div +1;
    
    pwm_128step pwm_led_r(.clk(clk), .reset_p(reset_p), 
                .duty(clk_div[27:21]), .pwm_freq(10000), .pwm_128(led_pwm[0]));
    pwm_128step pwm_led_g(.clk(clk), .reset_p(reset_p), 
                .duty(clk_div[26:20]), .pwm_freq(10000), .pwm_128(led_pwm[1]));
    pwm_128step pwm_led_b(.clk(clk), .reset_p(reset_p), 
                .duty(clk_div[25:19]), .pwm_freq(10000), .pwm_128(led_pwm[2]));          
    pwm_128step pwm_o(.clk(clk), .reset_p(reset_p), 
                .duty(clk_div[27:21]), .pwm_freq(10000), .pwm_128(led_pwm[3]));                  
endmodule

///////////////////////////////////////////////////////////////////////////////////////

module dc_motor_pwm_top(
    input clk, reset_p,
    output motor_pwm
    );
    
    reg[29:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    pwm_128step pwm_motor(.clk(clk), .reset_p(reset_p), 
            .duty(clk_div[10:4]), .pwm_freq(100), .pwm_128(motor_pwm));   //모터에 1000 이 최적화
   
endmodule
//////////////////////////////////////////
module dc_motor_pwm_top_1(
    input clk, reset_p,
    output motor_pwm
    );
    
    reg[29:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    pwm_100pc pwm_motor(.clk(clk), .reset_p(reset_p), 
            .duty(50), .pwm_freq(50), .pwm_100pc(motor_pwm));   //모터에 1000 이 최적화
   
endmodule
////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////
module servo_motor_pwm_top(
    input clk, reset_p,
    input [2:0] btn,
    output motor_pwm
    );
    wire [2:0] motor_pwm_w;
    wire [2:0] btn_pedge;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1])); 
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    reg [2:0]clk_w;
    wire clk_w1;
    reg [2:0] state;
   
   
   
    assign clk_w1= clk;
    
    always @ (posedge clk or posedge reset_p) begin
        if (reset_p) begin          
            clk_w=0;            
            state = 0;          
        end
        
        else if ( btn_pedge[0]) begin
                       
            state = 0;
            state[0] = 1;
            clk_w[0] = clk_w1;           
        end
            
        else if (btn_pedge[1]) begin
                       
             state = 0;
             state[1] = 1;
             clk_w[1] = clk_w1;                         
        end     
        
        else if (btn_pedge[2]) begin
             state = 0;
             state[2] = 1;
             clk_w[2] = clk_w1;          
        end
    end        

     pwm_100pc pwm_motor(.clk(clk), .reset_p(reset_p), 
            .duty(5), .pwm_freq(50), .pwm_100pc(motor_pwm_w[0]));
     
     pwm_100pc pwm_motor_1(.clk(clk), .reset_p(reset_p), 
            .duty(75), .pwm_freq(50), .pwm_100pc(motor_pwm_w[1]));
            
     pwm_100pc pwm_motor_2(.clk(clk), .reset_p(reset_p), 
            .duty(10), .pwm_freq(50), .pwm_100pc(motor_pwm_w[2]));
            
            
    
assign motor_pwm = state[0] ? motor_pwm_w[0] : 
                       state[1] ? motor_pwm_w[1] : motor_pwm_w[2];
endmodule
///////////////////////////////////////////////////////
module servo_motor_pwm_top_1(
    input clk, reset_p,
    input [2:0] btn,
    output motor_pwm
    );
    wire [2:0] motor_pwm_w;
    wire [2:0] btn_pedge;
    reg [3:0] state;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1])); 
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
     
    always @ (posedge clk or posedge reset_p) begin
        if (reset_p) begin                               
            state = 0;          
        end
        
        else if ( btn_pedge[0]) begin                       
            state = 0;
            state[0] = 1;                      
        end
            
        else if (btn_pedge[1]) begin                     
             state = 0;
             state[1] = 1;                                  
        end     
        
        else if (btn_pedge[2]) begin
             state = 0;
             state[2] = 1;
        end        
    end        

     pwm_128step pwm_motor(.clk(clk), .reset_p(reset_p), 
            .duty(10), .pwm_freq(50), .pwm_128(motor_pwm_w[0]));
     
     pwm_128step pwm_motor_1(.clk(clk), .reset_p(reset_p), 
            .duty(13), .pwm_freq(50), .pwm_128(motor_pwm_w[1]));           
    
    pwm_128step pwm_motor_3(.clk(clk), .reset_p(reset_p), 
            .duty(7), .pwm_freq(50), .pwm_128(motor_pwm_w[2])); 
                   
assign motor_pwm = state[0] ? motor_pwm_w[0] : 
                       state[1] ? motor_pwm_w[1] : 
                        motor_pwm_w[2] ? motor_pwm_w[2] :0 ;
endmodule
///////////////////////////////////////////////////////////////
module servo_sg90(
    input clk, reset_p,
    input [2:0] btn,
    output sg90,
    output [3:0] com,
    output [7:0] seg_7
    );
    
    wire [2:0] btn_pedge;
      
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1])); 
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    reg[31:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    wire clk_div_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[28]),.p_edge(clk_div_pedge));
    
    reg [17:0] duty;
    reg up_down;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            duty = 12;
            up_down = 1;
        end
        else if(btn_pedge[0]) begin
            if(up_down) up_down = 0;
            else up_down = 1;
        end
        
        else if(btn_pedge[1]) begin
            duty = 12;
        end    
        
        else if(btn_pedge[2]) begin
            duty = 65;
        end    
                
        else if (clk_div_pedge) begin
             if (duty >= 65 ) up_down = 0;
             else if (duty <= 14) up_down = 1;          
                 if(up_down) duty = duty +1;
                 else duty = duty -1;           
             end
        end
    
    pwm_512_period servo(.clk(clk), .reset_p(reset_p), 
            .duty({duty}), .pwm_period(2000000), .pwm_512(sg90));
    wire [15:0] bcd_duty;
    
    bin_to_dec dist(.bin({3'b0, duty}), .bcd(bcd_duty));
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_duty), .seg_7_ca(seg_7), .com(com));
    
endmodule
/////////////////////////////////////////////////////
module servo_sg90_1(
    input clk, reset_p,
    input [2:0] btn,
    output sg90,
    output [3:0] com,
    output [7:0] seg_7
    );
    
    wire [2:0] btn_pedge;
      
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1])); 
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    reg[31:0] clk_div;
    always @(posedge clk) clk_div = clk_div +1;
    
    wire clk_div_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(clk_div[22]),.p_edge(clk_div_pedge));
    
    reg [21:0] duty;
    reg up_down;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            duty = 58_000;
            up_down = 1;
        end
        else if(btn_pedge[0]) begin
            if(up_down) up_down = 0;
            else up_down = 1;
        end
        
        else if(btn_pedge[1]) begin
            duty = 58_000;
        end    
        
        else if(btn_pedge[2]) begin
            duty = 256_000;
        end    
                
        else if (clk_div_pedge) begin
             if (duty >= 256_000 ) up_down = 0;
             else if (duty <= 58_000) up_down = 1;          
                 if(up_down) duty = duty +1000;
                 else duty = duty -1000;           
             end
        end
    
    pwm_512_period servo(.clk(clk), .reset_p(reset_p), 
            .duty(duty), .pwm_period(2_000_000), .pwm_512(sg90));
    wire [15:0] bcd_duty;
    
    bin_to_dec dist(.bin(duty[21:10]), .bcd(bcd_duty));
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_duty), .seg_7_ca(seg_7), .com(com));
    
endmodule
///////////////////////////////////////////////////////
module ADC_top(
    input clk, reset_p,
    input vauxp14, vauxn14,
    output [3:0] com,
    output [7:0] seg_7,
    output led_pwm
);
    wire [4:0] channel_out;
    wire eoc_out;
    wire [15:0] do_out;
    
    xadc_wiz_1 adc_ch14(
        .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
        .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
        .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
         //di_in,               // Input data bus for the dynamic reconfiguration port
         //dwe_in,              // Write Enable for the dynamic reconfiguration port
         .reset_in(reset_p),            // Reset signal for the System Monitor control logic
         .vauxp14(vauxp14),              // Auxiliary channel 6
         .vauxn14(vauxn14),
//         busy_out,            // ADC Busy signal
         .channel_out(channel_out),         // Channel Selection Outputs
         .do_out(do_out),              // ADC 아날로그를 디지털로 컨버팅한 값
//         drdy_out,            // Data ready signal for the dynamic reconfiguration port
         .eoc_out(eoc_out)             // End of Conversion Signal
//         eos_out,             // End of Sequence Signal   //a 2 dc 컨버팅 끝낫다는 뜻
//         alarm_out,           // OR'ed output of all the Alarms    
//         vp_in,               // Dedicated Analog Input Pair
//         vn_in
);
    wire eoc_out_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(eoc_out),.p_edge(eoc_out_pedge));
    
    reg [11:0] adc_value;
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) adc_value = 0;
        else if(eoc_out_pedge) adc_value = {4'b0,do_out[15:8]}; //12비트 우shift로 나눠준 효과==>상위 비트 쓰면서 정밀도는 줄지만 오차도 줄어드는 장점
    end
    
    wire [15:0] bcd_value;
    bin_to_dec adc_bcd(.bin(adc_value), .bcd(bcd_value));
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(bcd_value), 
    .seg_7_ca(seg_7), .com(com));
    
    pwm_128step pwm_led(.clk(clk), .reset_p(reset_p), 
            .duty(do_out[15:9]), .pwm_freq(10000), .pwm_128(led_pwm));

endmodule // 1볼트 들어오면 1024 값 반환, 0.5는 512

/////////////////////////////////////////////////////////////
module adc_sequence2_top( //채널 2개
    input clk, reset_p,
    input vauxp14, vauxn14,    //adc14번핀,  14번핀gnd
    input vauxp15, vauxn15,  //adc15번핀  ,15번핀gnd
    output led_r, led_g,
    output [3:0] com,
    output [7:0] seg_7);
    wire [4:0] channel_out;
    wire [15:0] do_out;
    wire eoc_out,eoc_out_pedge;
    adc_ch_14_15 adc_seq2
         (
         .daddr_in({2'b0,channel_out}),            // Address bus for the dynamic reconfiguration port
         .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
         .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
         .reset_in(reset_p),            // Reset signal for the System Monitor control logic
         .vauxp14(vauxp14),              // Auxiliary channel 6
         .vauxn14(vauxn14),
         .vauxp15(vauxp15),             // Auxiliary channel 15
         .vauxn15(vauxn15),
         .channel_out(channel_out),         //channel_out에 1이 나오면 6번 채널 
                                             //2가 나오면 15번 채널  // Channel Selection Outputs
         .do_out(do_out),              // Output data bus for dynamic reconfiguration port
         .eoc_out(eoc_out),             // End of Conversion Signal
         .eos_out(eos_out)             // End of Sequence Signal
         );
     edge_detector_n eoc(.clk(clk), .reset_p(reset_p),.cp(eoc_out), .p_edge(eoc_out_pedge));
     
     reg [11:0] adc_value_x,adc_value_y;
     always @(posedge clk or posedge reset_p) begin
        if(reset_p)begin
            adc_value_x = 0;
            adc_value_y = 0;
        end
        else if(eoc_out_pedge) begin
            case(channel_out[3:0]) //최상위 비트 떼버림
                14: adc_value_x = {4'b0,do_out[15:10]}; //channel_out이  14번일때
                15: adc_value_y = {4'b0,do_out[15:10]}; //channel_out이  15번일때
            endcase
        end
     end
    
     wire [15:0] bcd_value_x, bcd_value_y;
     bin_to_dec adc_x_bcd(.bin(adc_value_x), .bcd(bcd_value_x));
     bin_to_dec adc_y_bcd(.bin(adc_value_y), .bcd(bcd_value_y));
     
     fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), 
        .value({bcd_value_x[7:0],bcd_value_y[7:0]}), .seg_7_ca(seg_7), .com(com));
     
     wire eos_out_pedge;
     edge_detector_n eos(.clk(clk), .reset_p(reset_p),.cp(eos_out), .p_edge(eos_out_pedge));
     
     reg [6:0] duty_x, duty_y;
     always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            duty_x = 0;
            duty_y = 0;
        end
        else if(eos_out_pedge) begin
            duty_x = adc_value_x[6:0];
            duty_y = adc_value_y[6:0];
        end
     end
     
     pwm_128step pwm_led_r(.clk(clk), .reset_p(reset_p), 
            .duty(bcd_value_x[6:0]), .pwm_freq(10000), .pwm_128(led_r));
     pwm_128step pwm_led_g(.clk(clk), .reset_p(reset_p), 
            .duty(bcd_value_y[6:0]), .pwm_freq(10000), .pwm_128(led_g));
endmodule
/////////////////////////////////////////////////////////////////////////////////
module I2C_master_top(
    input clk, reset_p,
    input [1:0] btn,
    output [7:0] led, 
    output sda, scl
    );
    
    reg [7:0] data;
    reg valid; 
    
    I2C_master master(.clk(clk), .reset_p(reset_p), .rd_wr(0), 
                .addr(7'h27), .data(data), .valid(valid), .sda(sda), .scl(scl));
                //rd=1, wr=0--> write만 할거야  //addr에 7'h27값은 데이터 시트 상 주소값
    
    wire [1:0] btn_pedge, btn_nedge;            
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), 
            .btn_pe(btn_pedge[0]), .btn_ne(btn_nedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), 
            .btn_pe(btn_pedge[1]), .btn_ne(btn_nedge[1]));
    
    always @ (posedge clk or posedge reset_p) begin
        if(reset_p) begin
            data = 0;
            valid = 0;            
        end
        else begin
            if(btn_pedge[0]) begin
                data = 8'b0000_0000;
                valid = 1;
            end
            else if(btn_nedge[0]) valid = 0;
            else if(btn_pedge[1]) begin
                data = 8'b1111_1111;
                valid = 1;    
            end
            else if(btn_nedge[1]) valid = 0;
        end
    end
endmodule
/////////////////////////////////////////////
module i2c_txtlcd_top(
    input clk, reset_p,
    input [3:0]btn,
    output scl, sda);

    parameter IDLE          = 6'b00_0001;    // pushed btn waiting
    parameter INIT          = 6'b00_0010;    // text initial in lcd
    parameter SEND          = 6'b00_0100;    // 'A'
    parameter MOVE_CURSOR   = 6'b00_1000;
    parameter SHIFT_DISPLAY = 6'b01_0000;
    parameter SAMPLE_DATA = "A";    // " "는 verilog에서 'ascii code'로 변환되서 출력
    
    reg [7:0] send_buffer; // lcd send byte
    reg send_e, rs;
    wire busy;  // 읽어야하는 것

    i2c_lcd_send_byte send_byte(.clk(clk), .reset_p(reset_p),
        .addr(7'h27), .send_buffer(send_buffer), 
        .send(send_e), .rs(rs),
        .scl(scl), .sda(sda), .busy(busy));
       
    reg [21:0] count_usec;
    reg count_usec_e;
    wire clk_usec;
    clock_usec usec_clk (clk, reset_p, clk_usec);

    always @(negedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec = 0;
        end
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;
        end
    end
    
    reg [5:0] state, next_state; // state change(천이?)
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) state = IDLE;
        else state = next_state;
    end
   
    wire [2:0]btn_pedge;   // btn cntr & controller
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), 
        .btn(btn[0]), .btn_pe(btn_pedge[0]), .btn_ne(btn_nedge));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), 
            .btn(btn[1]), .btn_pe(btn_pedge[1]), .btn_ne(btn_nedge));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), 
            .btn(btn[2]), .btn_pe(btn_pedge[2]), .btn_ne(btn_nedge));  
     
    reg init_flag;  /// 초기화 됐는지 확인(flag)
    reg [3:0] cnt_data;
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            send_buffer = 0;     //4bit data(our)
            send_e = 0;          //lcd enable
            rs = 0;              //register select
            init_flag = 0;
            cnt_data =0;
        end
        else begin
            case(state)
                IDLE: begin  // 시스템 시작 시 text 초기화 확인(됐는지) & btn wait(valid)
                    if(init_flag)begin      // (4) init state에서 1
                        if(btn_pedge[0])next_state = SEND;
                        else if(btn_pedge[1]) next_state = MOVE_CURSOR; // (5) btn(valid) wait             
                        else if(btn_pedge[2]) next_state = SHIFT_DISPLAY;             
                    end
                    else begin
                        if(count_usec <= 22'd80_000)begin   // (1) init_flag = 0
                            count_usec_e = 1;   //*         //     init 전 count
                        end
                        else begin          // (2) 40ms 후 next_state = init
                            next_state = INIT;
                            count_usec_e = 0;
                        end     
                    end
                end 
                INIT: begin     // (3) Init : init_flag = 1
                    if(count_usec <= 22'd1000)begin // 1ms
                        send_buffer = 8'h33;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd1010) send_e = 0;   // send_e = 0을 위한 for 10us
                    else if(count_usec <= 22'd2010)begin
                        send_buffer = 8'h32;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd2020) send_e = 0;
                    else if(count_usec <= 22'd3020)begin
                        send_buffer = 8'h28;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd3030) send_e = 0;
                    else if(count_usec <= 22'd4030)begin
                        send_buffer = 8'h0e;    // 08은 off
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd4040) send_e = 0;
                    else if(count_usec <= 22'd5040)begin
                        send_buffer = 8'h01;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd5050) send_e = 0;
                    else if(count_usec <= 22'd6050)begin
                        send_buffer = 8'h06;   
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd6060) send_e = 0;
                    else begin
                        next_state = IDLE;
                        init_flag = 1;
                        count_usec_e = 0;
                    end
                end
                SEND: begin
                    if(busy)begin   // 통신중, btn 무시 -> 다시 IDLE로
                        next_state = IDLE;
                        send_e = 0;
                        cnt_data = cnt_data +1;
                    end
                    else begin  
                         send_buffer = SAMPLE_DATA + cnt_data;
                         rs = 1;
                         send_e = 1;
                    end                            
                 end
                 MOVE_CURSOR: begin
                    if(busy)begin   // 통신중, btn 무시 -> 다시 IDLE로
                        next_state = IDLE;
                        send_e = 0;                        
                    end
                    else begin  
                         send_buffer = 8'hc0;
                         rs = 0;
                         send_e = 1;
                    end                            
                 end
                  SHIFT_DISPLAY: begin
                    if(busy)begin   // 통신중, btn 무시 -> 다시 IDLE로
                        next_state = IDLE;
                        send_e = 0;                        
                    end
                    else begin  
                         send_buffer = 8'h1c;
                         rs = 0;
                         send_e = 1;
                    end                            
                 end
            endcase
        end
    end
endmodule
///////////////////////////////////////////////////////