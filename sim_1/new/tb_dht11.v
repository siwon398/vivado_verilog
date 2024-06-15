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
    tri1 dht11_data;   //3����۷� inout ���� Ǯ���� ���̾�(test bench��)
    wire [7:0] humidity, temperature;
   
    dht11 DUT(clk, reset_p, dht11_data, humidity, temperature);

    reg dout, wr;
    assign dht11_data = wr ? dout : 1'bz;

    parameter [7:0] humi_value = 8'd80;
    parameter [7:0] tmpr_value = 8'd25;
    parameter [7:0] check_sum = humi_value + tmpr_value;
    parameter [39:0] data = {humi_value, 8'b0, tmpr_value, {8{1'b0}}, check_sum}; //{8{1'b0}} -> 8�� �ݺ��ϴ� �ݺ���   
    //���ÿ��� dht11�� ���Ǵ��� ����ϰ� �ִٰ�, dht11����� ��ŸƮ��ȣ �Է����ٶ����� �������
    
    initial begin       //�ʱⰪ
        clk = 0;
        reset_p = 1; #10;
        wr = 0;
    end
 
    always #5 clk = ~clk;    //#5==������ 5ns �Ŀ� 0���� 1�ǰ�, 5 �Ŀ� 0 ��==>�ֱ� 10ns
    
    integer i;
     
    initial begin 
        // MCU signal
        #10;
        reset_p = 0;    //��Ŭ�� �Ŀ� ������ 0���� �ٲ���
        wait(!dht11_data);  //c����� while �� ������ ==> dht11_data�� 0�� �ɋ�����
        wait(dht11_data);     
        #20000;       //20us ��޷�
        
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
        $stop;   //�ùķ��̼� ����
    end
endmodule



