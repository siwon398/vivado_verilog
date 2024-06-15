`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/04/18 12:29:09
// Design Name: 
// Module Name: tb_dht11
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_dht11();
    reg clk, reset_p;
    tri1 dht11_data;   //3상버퍼로 inout 설정 풀업된 와이어(test bench만)
    wire [7:0] humidity, temperature;
   
    dht11 DUT(clk, reset_p, dht11_data, humidity, temperature);

    reg dout, wr;
    assign dht11_data = wr ? dout : 1'bz;

    parameter [7:0] humi_value = 8'd80;
    parameter [7:0] tmpr_value = 8'd25;
    parameter [7:0] check_sum = humi_value + tmpr_value;
    parameter [39:0] data = {humi_value, 8'b0, tmpr_value, {8{1'b0}}, check_sum}; //{8{1'b0}} -> 8번 반복하는 반복문   
    //평상시에는 dht11에 임피던스 출력하고 있다가, dht11모듈이 스타트신호 입력해줄때무터 출력해줘
    
    initial begin       //초기값
        clk = 0;
        reset_p = 1; #10;
        wr = 0;
    end
 
    always #5 clk = ~clk;    //#5==딜레이 5ns 후에 0에서 1되고, 5 후에 0 됨==>주기 10ns
    
    integer i;
     
    initial begin 
        // MCU signal
        #10;
        reset_p = 0;    //한클럭 후에 리셋을 0으로 바꿔줘
        wait(!dht11_data);  //c언어의 while 문 같은거 ==> dht11_data가 0이 될떄까지
        wait(dht11_data);     
        #20000;       //20us 기달려
        
         // DHT11 siganl                              
        dout  = 0; wr = 1; #80000;
        wr = 0; #80000;
        wr = 1;
        for (i=0; i<40; i=i+1)begin
            dout = 0; #50000;
            dout = 1;
            if(data[39-i]) #70000;
            else         #27000;
        end
        dout = 0; wr = 1; #10;
        wr = 0; #10000;
        $stop;   //시뮬레이션 종료
    end
endmodule



