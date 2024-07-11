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
        else if (cnt_sysclk >=99) cnt_sysclk = 0;      //cnt_sysclk[0]�� �̿��ϴµ� 1usec������ �����ϸ鼭 124�� �����ϰ� �׶� cnt_sysclk[6]������ۿ� ����
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
    
    reg [9:0] cnt_clk_source;//1000��
    reg cp_div_1000;
    
//    always @(posedge clk or posedge reset_p) begin//���⼭
//        if(reset_p)cnt_clk_source =0;
//        else if(clk_source) begin
//            if(cnt_clk_source > 999) cnt_clk_source =0;
//            else cnt_clk_source = cnt_clk_source +1;
//        end
//    end
//    assign cp_div_1000 = cnt_clk_source >= 499 ? 1 : 0;//�������   //500msec���� 0.���� 500msec����1 //300�ص� ÷ 300�� 0 ������ 700�� 1
    
     always @(posedge clk or posedge reset_p) begin//���⼭
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
    end//�������
    
    
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(cp_div_1000), .n_edge(clk_div_1000));
    
    endmodule
    //////////////////////////////////////////////
    

//////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////
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
                if(dec1 == 0) begin  //0���� �۾��� �� ����
                     dec1 = 9;
                     if (dec10 == 0) begin
                        dec10 =5;
                        dec_clk = 1; // cooktimer����� �� 00����  59�� ���� �� 1�б��̰� ����ȭ  
                     end
                     else dec10 = dec10 - 1;    
                end     
                else dec1 = dec1 -1;
            end            
            else dec_clk =0; // ���⼭ 0 �ؼ� ���� ���� �ʿ� ���� (one cycle pulse��)
        end
    end
endmodule
    //////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////
module sr04_div58(
    input clk, reset_p,
    input clk_usec, cnt_e,
    output reg [11:0] cm
    );    
    integer cnt;     
     always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cm = 0;
            cnt = 0;
        end
        else begin
            if(cnt_e) begin 
                if(clk_usec)begin
                    cnt = cnt +1;
                    if(cnt >= 58) begin
                        cnt = 0;
                        cm = cm +1;
                    end               
                end     
            end    
        
            else begin
                cnt = 0;
                cm  = 0;
            end
        end    
      end               
endmodule