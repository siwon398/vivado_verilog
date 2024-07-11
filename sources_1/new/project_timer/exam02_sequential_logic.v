`timescale 1ns / 1ps


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


 module ring_counter_fnd(
    input clk, reset_p,
    output reg [3:0] com
    );
    
    reg [16:0] clk_div;
    wire clk_div_16;
    always @(posedge clk) clk_div = clk_div +1;
    
    edge_detector_n ed (.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
    
    always @(posedge clk_div[16] or posedge reset_p) begin //[13]���ں�ȭ��
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
            ff_cur <= cp;       //'ff_cur = cp' �̷��Ը� ����  blocking�� ��
            ff_old <= ff_cur;   //(���� �ڵ尡 ����� ���� ���� �ڵ� ������ ����
                                //==> 'ff_cur = cp'����ɶ� 'ff_old <= ff_cur'���� �ȵ�
                                // '<=' ������ ���� ���ķ� ������
        end                     //  always �� ����  �����ϸ�nonblocking'<=' �����
    end
    
    assign p_edge = ({ff_cur, ff_old} == 2'b10) ? 1 : 0;
    assign n_edge = ({ff_cur, ff_old} == 2'b01) ? 1 : 0;
endmodule
//////////////////////////////////////////////////////////////////
