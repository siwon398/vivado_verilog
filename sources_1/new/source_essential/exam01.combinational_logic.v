`timescale 1ns / 1ps

module and_gate(        //and gate ���
    input A,            //and gat ��� �Է�
    input B,            //ag ��� �Է�
    output F            //ag ��� ���
    );
    
    and (F, A, B);      //and gate(���, �Է�, �Է�)==>and gate�� �Է� ������ ����,   ����� 1����
    
    
endmodule               //ag ��� ����

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module half_adder_structural(       //�ݰ���� ���
    input A, B,                     //��� �Է� ����2�� ����
    output sum, carry               //��� ��� ���� 2�� ����
    );
    
    xor (sum, A, B);                //xor(���, ��, ��)==>xor:�ٸ��Է�=1,  �����Է�=0
    and (carry, A, B);              //and(��, �� ��)
    
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module half_adder_behaviaral(
    input A, B,
    output reg sum, carry           // always �� �ȿ� �ִ� �������� register���� ���� �������
    );
    
                                     //��� �Է¿� ����   case���� ���� ���� ��
    always @(A, B) begin            //a,b ������  �ٲ�� ����(�Ʒ�) ���� ����
                                     // always �� �ȿ� �ִ� �������� register���� ���� �������************
        case({A,B})                 //a,b�� �߰�ȣ�� ����
            2'b00: begin sum= 0; carry = 0; end    //2==2bit     b=���̳ʸ� = ������,    00==0A , 0B
            2'b01: begin sum =1; carry = 0; end
            2'b10: begin sum= 1; carry = 0; end
            2'b11: begin sum =0; carry = 1; end
            
        endcase
    end
    
                                        //�����α� ������ wire, reg �ΰ��� �־�
 endmodule
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 module half_adder_dataflow(
    input A,B,
    output sum, carry
     );
 
    wire [1:0] sum_value;            //1���� 0���� 2bit sumvalue��� ���������
    
    assign sum_value = A + B;       //assign���� ��¹���   wire ��������**********
                                     //wire�� ��,,  register�� �޸�*************
    
    assign sum = sum_value[0];      //0����Ʈ==1���ڸ�
    assign carry = sum_value[1];    //1����Ʈ==10���ڸ�(2����)
     
 endmodule
//////////////////////////////////////////////////////////////////////////////////////

module full_adder_structural(
    input A, B, cin,
    output sum, carry
);

    wire sum_0, carry_0, carry_1;
    
    half_adder_structural ha0 (.A(A), .B(B), .sum(sum_0), .carry(carry_0));
       /*ù���� A�� �ݰ����,  
         (A)�� ������� A 
          ===> ��͵��� �ݰ���� ����� ������ �ҷ��� wire�� ������*/
    
    half_adder_structural ha1 (.A(sum_0), .B(cin), .sum(sum), .carry(carry_1));
        //ù��°  sum�� �ݰ����1��,    (sum)�� ������� sum
    
    or (carry, carry_0, carry_1);
    
endmodule
////////////////////////////////////////////////////////////////////////////////////
module full_adder_behaviaral(
    input A, B, cin,
    output reg sum, carry
);

 always @(A, B, cin) begin        
        case({A,B,cin})               
            3'b000: begin sum= 0; carry = 0; end    
            3'b001: begin sum =1; carry = 0; end
            3'b010: begin sum= 1; carry = 0; end
            3'b011: begin sum =0; carry = 1; end
            3'b100: begin sum =1; carry = 0; end
            3'b101: begin sum= 0; carry = 1; end
            3'b110: begin sum =0; carry = 1; end
            3'b111: begin sum =1; carry = 1; end
            
        endcase
    end
    
endmodule
/////////////////////////////////////////////////////////////////////////
module full_adder_dataflow(
    input A, B, cin,
    output sum, carry
    );
    
    wire [1:0] sum_value;
    
    assign sum_value = A+ B+ cin;
    assign sum = sum_value[0];
    assign carry =sum_value[1];
    
endmodule
//////////////////////////////////////////////////////////////////
module fadder_4bit_s(
    input [3:0] A,B,
    input cin,
    output [3:0] sum,
    output carry
    );
    
    wire [2:0] carry_w; //�׸� �׸��� wire 3�� �߰��ؾߵ�
    
    full_adder_structural fa0 (.A(A[0]), .B(B[0]),
        .cin(cin), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1 (.A(A[1]), .B(B[1]),
        .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    full_adder_structural fa2 (.A(A[2]), .B(B[2]),
        .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3 (.A(A[3]), .B(B[3]),
        .cin(carry_w[2]), .sum(sum[3]), .carry(carry));
   
endmodule
///////////////////////////////////////////////////////////////////

module fadder_4bit(
    input [3:0] A, B,
    input cin,
    output [3:0] sum,
    output carry
    );
    
    wire [4:0] temp; //4bit�� ���ϸ� 5��Ʈ ����
    
    assign temp =A + B +cin;
    assign sum  = temp[3:0];
    assign carry =temp[4];//OOOOO �߿� �� �տ� = [4][3][2][1][0] = carry sum sum sum sum

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////


module fadd_sub_4bit_s(
    input [3:0] A,B,
    input cin, s, //add : s =0,      sub : s = 1
    output [3:0] sum,
    output carry
    );
    
    wire [2:0] carry_w; //�׸� �׸��� wire 3�� �߰��ؾߵ�
    
    wire s0;
    xor (s0, B[0], s);   //    ^ = xor,    & = and,   | = or,     ~ = not
    
    
    full_adder_structural fa0 (.A(A[0]), .B(B[0]^s),
        .cin(s), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1 (.A(A[1]), .B(B[1]^s),//wire  ���� �ٷ� ����              
        .cin(carry_w[0]), .sum(sum[1]), .carry(carry_w[1]));
    full_adder_structural fa2 (.A(A[2]), .B(B[2]^s),
        .cin(carry_w[1]), .sum(sum[2]), .carry(carry_w[2]));
    full_adder_structural fa3 (.A(A[3]), .B(B[3]^s),
        .cin(carry_w[2]), .sum(sum[3]), .carry(carry));
   
endmodule
/////////////////////////////////////////////////////////////////////////////////

module fadd_sub_4bit(
    input [3:0] A, B,
    input s,
    output [3:0] sum,
    output carry
    );
    
    wire [4:0] temp; 
    
    assign temp = s ? A - B : A + B;
    assign sum  = temp[3:0];
    assign carry =~temp[4];

endmodule
////////////////////////////////////////////////////////////

module comparator_dataflow(
    input A, B,
    output equal, greater, less
    );
    
    assign equal = (A==B) ? 1'b1 : 1'b0;     //assign equal = A ~^ B;
    assign greater = (A>B) ? 1'b1 : 1'b0;   //assign greater =  A & ~B;
    assign less = (A<B) ? 1'b1 : 1'b0;      //assign less = ~A & B;

endmodule
  /////////////////////////////////////////////////////////////////////////  

module comparator #(parameter N = 8)(

    input [N-1:0] A, B,
    output equal, greater, less
    );
    
    assign equal = (A==B) ? 1'b1 : 1'b0;   
    assign greater = (A>B) ? 1'b1 : 1'b0; 
    assign less = (A<B) ? 1'b1 : 1'b0;     

endmodule

//////////////////////////////////////////////////
module comparator_N_bit_test(
    input [1:0] A, B,
    output equal, greater, less);
    
    comparator #(.N(2)) c_16 (.A(A), .B(B),
        .equal(equal), .greater(greater), .less(less));    
         //���� comparator_N_bit��� �̿��ؼ� 16��Ʈ �񱳱� �����
        
endmodule
////////////////////////////////////////////////////////////
module comparator_N_bit_b #(parameter N = 8)(

    input [N-1:0] A, B,
    output reg equal, greater, less
    );
    
    always @(A, B) begin
       if( A==B) begin
            equal = 1;
            greater = 0;
            less = 0;
       end 
       
       else if ( A>B) begin       //else������ ���� ���� �¾Ƶ� �ؿ� ���� ���غ�,
            equal=0;              //  else������  ���� ���� ���� �� else���� ���� ����
            greater =1;
            less=0;
            
       end
       
       else begin    //if�� ��������  else begin ������ latchȸ�� ���������, latchȸ�� ����� �ȵ�
            equal=0;
            greater =0;
            less=1;
       end        
    end
endmodule
//////////////////////////////////////////////////////////////////////
module decoder_2_4_s(
    input [1:0] code,
    output [3:0] signal
    );
    
    wire [1:0] code_bar;
    not (code_bar[0], code[0]);
    not (code_bar[1], code[1]);
    
    and(signal[0], code_bar[1], code_bar[0]);
    and(signal[1], code_bar[1], code[0]);
    and(signal[2], code[1], code_bar[0]);
    and(signal[3], code[1], code[0]);
endmodule

////////////////////////////////////////////////////////

module decoder_2_4_b(
    input [1:0] code,
    output reg [3:0] signal
    );
    always @(code)begin     //begin end ���� �Ұ� -->���� ������
        if          (code==0) signal = 4'b0001;
        else if (code==2'b01) signal = 4'b0010;
        else if (code==2'b10) signal = 4'b0100;
        else                  signal = 4'b1000;
    end
endmodule

   
//    always @(code) begin        //begin end��������--> case�� �Ѱ���
//        case(code)
//            2'b00: signal =4'b0001;
//            2'b01: signal =4'b0010;
//            2'b10: signal =4'b0100;
//            2'b11: signal =4'b1000;
//        endcase
//    end
//endmodule

/////////////////////////////////////////////
module decoder_2_4_d(
    input [1:0] code,
    output [3:0] signal
    );
    
    assign signal = (code ==2'b00) ? 4'b0001 : 
        (code==2'b01) ? 4'b0010 :
        (code==2'b10) ? 4'b0100 : 4'b1000;    
    
endmodule
///////////////////////////////////////////////////////

module encoder_4_2(
    input [3:0] signal,
    output [1:0] code
    );
    
    assign code = (signal == 4'b0001) ? 2'b00 :
        (signal == 4'b0010) ? 2'b01 : 
        (signal == 4'b0100) ? 2'b10 : 2'b11;

endmodule        
////////////////////////////////////////////

module decoder_2_4_en(
    input [1:0] code,
    input enable,
    output [3:0] signal
);

    assign signal = (enable==1'b0) ? 4'b0000 : (code==2'b00) ? 4'b0001 :
        (code == 2'b01) ? 4'b0010 : (code == 2'b10) ? 4'b0100 : 4'b1000;
        
endmodule
/////////////////////////////////////////////////////

module decoder_3_8(
    input [2:0] code,
    output [7:0] signal
    );
    
    decoder_2_4_en dec_low (.code(code[1:0]), .enable(~code[2]), .signal(signal[3:0]));
    decoder_2_4_en dec_high (.code(code[1:0]), .enable(code[2]), .signal(signal[7:4]));

endmodule
//////////////////////////////////////
module decoder_2_4_en_b(
    input [1:0] code,
    input enable,
    output reg [3:0] signal
    );
    always @(code,enable)begin     //begin end ���� �Ұ� -->���� ������
        if (enable==1) begin
              case(code)
                2'b00: signal =4'b0001;
                2'b01: signal =4'b0010;
                2'b10: signal =4'b0100;
                2'b11: signal =4'b1000;
              endcase
        end
        
        else begin 
                signal = 0;
        end 
     end
endmodule
//////////////////////////////////////////////////


 ////////////////////////////////////////////////
module decoder_3_8_b(
    input [2:0] code,
    output [7:0] signal
    );
    decoder_2_4_en_b dec_low (.code(code[1:0]), .enable(~code[2]), .signal(signal[3:0]));
    decoder_2_4_en_b dec_high (.code(code[1:0]), .enable(code[2]), .signal(signal[7:4]));
endmodule

 /////////////////////////////////////
 
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
        
///////////////////////////////////////
module mux_2_1(
    input  d0,d1,
    input s,
    output f
    );
    
    assign f= s ? d1 : d0;
//    wire sbar, w0,w1;
//    not(sbar,s);
//    and (w0, sbar, d[0]);//w0
//    and (w1,s,d[1]);//w1
//    or (f, w0,w1);//���f

endmodule
//////////////////////////////////////
module mux_4_1(
    input[3:0] d,
    input [1:0] s,
    output f);
    
    assign f= d[s];//d[00] d[01] d[10] d[11]
endmodule
/////////////////////////////////////////
module mux_8_1(
    input[7:0] d,
    input [2:0] s,
    output f);
    
    assign f= d[s];
endmodule
///////////////////////////////////
module demux_1_4(
    input d,
    input [1:0] s,
    output [3:0] f);
    
    assign f= (s==2'b00) ? {3'b000, d} :        //000d
              (s==2'b01) ? {2'b00, d, 1'b0} :   //00d0
              (s==2'b10) ? {1'b0, d,2'b00} :    //0d00
                           {d,3'b000};          //d000
 endmodule
 //////////////////////////////////////
 
 module mux_demux(
    input [7:0] d,
    input [2:0] s_mux,
    input [1:0] s_demux,
    input [3:0] f
    );
    wire w;
    mux_8_1 mux(.d(d), .s(s_mux), .f(w));
    demux_1_4 demux(.d(w), .s(s_demux), .f(f));
    
    endmodule
//////////////////////////////////////////
module bin_to_dec(
        input [11:0] bin,
        output reg [15:0] bcd
    );
    reg [3:0] i;
    always @(bin) begin
        bcd = 0;
        for (i=0;i<12;i=i+1)begin
            bcd = {bcd[14:0], bin[11-i]};
            if(i < 11 && bcd[3:0] > 4) bcd[3:0] = bcd[3:0] + 3;
            if(i < 11 && bcd[7:4] > 4) bcd[7:4] = bcd[7:4] + 3;
            if(i < 11 && bcd[11:8] > 4) bcd[11:8] = bcd[11:8] + 3;
            if(i < 11 && bcd[15:12] > 4) bcd[15:12] = bcd[15:12] + 3;
        end
    end
endmodule