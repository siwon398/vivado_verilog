`timescale 1ns / 1ps

module fan_top(
    input clk, reset_p, 
    input [3:0]btn,
    input echo,
    output trigger,
    output [3:0] com,
    output [7:0] seg_7,
    output motor_pwm,
    output light_pwm,
    output [2:0]led_power,
    output [2:0] led_timer
    );
    wire [16:0] value;
    wire btn_nedge;   
    wire [3:0] btn_pedge;
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));   //파워
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_ne(btn_nedge), .btn_pe(btn_pedge[1]));   //타이머
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    
    
    /* 타이머 모듈*/ 
    cook_timer_fan cook(clk, reset_p, btn_nedge, btn_pedge[1], value, led_timer);
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value[16:1]), .seg_7_ca(seg_7), .com(com));
   
    /*조명모듈*/
    wire [7:0] light;
    counter_pwm fan_light(.clk(clk), .reset_p(reset_p), .btn_pedge(btn_pedge[2]), .power(light));
    pwm_128step_fan pwm_light(.clk(clk), .reset_p(reset_p), .duty(light), .pwm_freq(100), .pwm_128(light_pwm));
    
    /*파워 모듈*/
    wire [7:0] power_fan;
    wire [7:0]power_timer;  //timer = 0일때 off
    counter_pwm fan_power(.clk(clk), .reset_p(reset_p), .btn_pedge(btn_pedge[0]), .power(power_fan), .led(led_power));         
    pwm_128step_fan pwm_motor(.clk(clk), .reset_p(reset_p), .duty(power_timer), .pwm_freq(100), .pwm_128(motor_pwm));               
    
    assign power_timer = value ? power_fan : 0; //timer = 0일때 off

//    always @(posedge clk or posedge reset_p) begin
//        if(reset_p) begin
        
//        end
//        else if (~btn_nedge) begin
        
//        end
//        else if (btn_nedge) begin
            
//        end
//    end    




    
//    wire [11:0] distance;
//    wire [11:0] distance_sw;
//    ultra_sonic_prof ult(clk, reset_p, echo, trigger, distance, led_bar);
    
//    assign power_timer = (11'h1a<=distance) ? 0 : power_fan;
//      //distance에 value
   
 endmodule     


//////////////////////////////////////////////////////////////////////
module dht11_top_fan(
    input clk, reset_p,
    inout dht11_data,
    output [3:0] com,
    output [7:0] seg_7
    );
    
    wire [7:0] humidity, temperature;
    dht11 dht(clk, reset_p, dht11_data, humidity, temperature);
    wire [15:0] bcd_humi, bcd_tmpr;
    bin_to_dec humi(.bin({4'b0000,humidity}), .bcd(bcd_humi));
    bin_to_dec tmpr(.bin({4'b0000, temperature}), .bcd(bcd_tmpr));
    
    wire [15:0] value;
    assign value = {bcd_humi[7:0], bcd_tmpr[7:0]};
    
    fnd_4digit_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .seg_7_ca(seg_7), .com(com));
    
endmodule
///////////////////////////////////////////////////////////////////
module i2c_txtlcd_top_fan(
    input clk, reset_p,
    input [3:0]btn,
    output scl, sda);

    parameter IDLE          = 6'b00_0001;    // pushed btn waiting
    parameter INIT          = 6'b00_0010;    // text initial in lcd
    parameter SEND          = 6'b00_0100;    // 'A'
    parameter MOVE_CURSOR   = 6'b00_1000;
    parameter SHIFT_DISPLAY = 6'b01_0000;
    parameter SAMPLE_DATA = "A";    // " "는 verilog에서 'ascii code'로 변환되서 출력
    parameter word_T = "T";
    parameter word_E = "E";
    parameter word_M = "M";
    parameter word_P = "P";
    parameter word_dot = ":";
    parameter word_H = "H";
    parameter word_U = "U";
    parameter word_I = "I";
    parameter word_D = "D";
    
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
        .btn(btn[0]), .btn_pe(btn_pedge[0]));
     
     
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
                    if (count_usec <= 22'd1000) begin  
                         send_buffer = word_H;
                         rs = 1;
                         send_e = 1;
                         count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd1010) send_e = 0;   // send_e = 0을 위한 for 10us
                    else if(count_usec <= 22'd2010)begin
                        send_buffer = word_M;
                        rs = 1;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd2020) send_e = 0;
                    else if(count_usec <= 22'd3020)begin
                        send_buffer = word_H;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd3030) send_e = 0;
                    else if(count_usec <= 22'd4030)begin
                        send_buffer = word_P;
                        send_e = 1;
                        count_usec_e = 1;
                    end   
                    else if(count_usec <= 22'd4040) send_e = 0;
                    else if(count_usec <= 22'd5040)begin
                        send_buffer = 8'hc0;
                        send_e = 1;
                        count_usec_e = 1;
                    end
                    else if(count_usec <= 22'd5050)begin
                        send_buffer = word_H;
                        send_e = 1;
                        count_usec_e = 1;
                    end                            
                 end
                
            endcase
        end
    end
endmodule
//////////////////////////////////////////////////////////////////
module i2c_txtlcd_top_1(
    input clk, reset_p,
    input [3:0]btn,
    output scl, sda);

    parameter IDLE          = 10'b00_0000_0001;    // pushed btn waiting
    parameter INIT          = 10'b00_0000_0010;    // text initial in lcd
    parameter SEND          = 10'b00_0000_0100;    // 'A'
    parameter MOVE_CURSOR   = 10'b00_0000_1000;
    parameter SHIFT_DISPLAY = 10'b00_0001_0000;
    parameter SAMPLE_DATA = "A";
    parameter word_M = "M";
    parameter ONE           = 10'b00_0010_0000;
    parameter TWO           = 10'b00_0100_0000;
    parameter THREE         = 10'b00_1000_0000;
    parameter FOUR          = 10'b01_0000_0000;
   
    
        // " "는 verilog에서 'ascii code'로 변환되서 출력
    
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
                    
                         send_buffer = SAMPLE_DATA;  
                         rs = 1;
                         send_e = 1;
                         next_state = ONE;
                        end                            
                  ONE : begin
                       
                         rs = 1;
                         send_e = 0;
                         next_state = TWO;
                 end               
                  TWO : begin
                        send_buffer = SAMPLE_DATA;  
                         rs = 1;
                         send_e = 1;
                    end
            endcase
        end
    end
endmodule