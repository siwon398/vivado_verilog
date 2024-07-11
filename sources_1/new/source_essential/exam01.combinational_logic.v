`timescale 1ns / 1ps

module and_gate(        //and gate 모듈
    input A,            //and gat 모듈 입력
    input B,            //ag 모듈 입력
    output F            //ag 모듈 출력
    );
    
    and (F, A, B);      //and gate(출력, 입력, 입력)==>and gate는 입력 여러개 가능,   출력은 1개만
    
    
endmodule               //ag 모듈 종료

////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module half_adder_structural(       //반가산기 모듈
    input A, B,                     //모듈 입력 변수2개 선엄
    output sum, carry               //모듈 출력 변수 2개 선언
    );
    
    xor (sum, A, B);                //xor(출력, 입, 입)==>xor:다른입력=1,  같은입력=0
    and (carry, A, B);              //and(출, 입 입)
    
endmodule

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module half_adder_behaviaral(
    input A, B,
    output reg sum, carry           // always 문 안에 있는 변수들은 register변수 선언 해줘야해
    );
    
                                     //모든 입력에 대한   case들을 정의 해준 것
    always @(A, B) begin            //a,b 변수가  바뀌면 안의(아래) 문법 동작
                                     // always 문 안에 있는 변수들은 register변수 선언 해줘야해************
        case({A,B})                 //a,b를 중괄호로 묶어
            2'b00: begin sum= 0; carry = 0; end    //2==2bit     b=바이너리 = 이진수,    00==0A , 0B
            2'b01: begin sum =1; carry = 0; end
            2'b10: begin sum= 1; carry = 0; end
            2'b11: begin sum =0; carry = 1; end
            
        endcase
    end
    
                                        //베릴로그 변수는 wire, reg 두가지 있어
 endmodule
 
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
 module half_adder_dataflow(
    input A,B,
    output sum, carry
     );
 
    wire [1:0] sum_value;            //1부터 0까지 2bit sumvalue라는 변수만들어
    
    assign sum_value = A + B;       //assign문의 출력문은   wire 선언해줘**********
                                     //wire는 선,,  register는 메모리*************
    
    assign sum = sum_value[0];      //0번비트==1의자리
    assign carry = sum_value[1];    //1번비트==10의자리(2진수)
     
 endmodule
//////////////////////////////////////////////////////////////////////////////////////

module full_adder_structural(
    input A, B, cin,
    output sum, carry
);

    wire sum_0, carry_0, carry_1;
    
    half_adder_structural ha0 (.A(A), .B(B), .sum(sum_0), .carry(carry_0));
       /*첫번쨰 A는 반가산기,  
         (A)는 전가산기 A 
          ===> 요것들을 반가산기 만들어 놓은거 불러서 wire로 연결함*/
    
    half_adder_structural ha1 (.A(sum_0), .B(cin), .sum(sum), .carry(carry_1));
        //첫번째  sum은 반가산기1번,    (sum)은 전가산기 sum
    
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
    
    wire [2:0] carry_w; //그림 그리면 wire 3개 추가해야돼
    
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
    
    wire [4:0] temp; //4bit수 더하면 5비트 나와
    
    assign temp =A + B +cin;
    assign sum  = temp[3:0];
    assign carry =temp[4];//OOOOO 중에 맨 앞에 = [4][3][2][1][0] = carry sum sum sum sum

endmodule
///////////////////////////////////////////////////////////////////////////////////////////////


module fadd_sub_4bit_s(
    input [3:0] A,B,
    input cin, s, //add : s =0,      sub : s = 1
    output [3:0] sum,
    output carry
    );
    
    wire [2:0] carry_w; //그림 그리면 wire 3개 추가해야돼
    
    wire s0;
    xor (s0, B[0], s);   //    ^ = xor,    & = and,   | = or,     ~ = not
    
    
    full_adder_structural fa0 (.A(A[0]), .B(B[0]^s),
        .cin(s), .sum(sum[0]), .carry(carry_w[0]));
    full_adder_structural fa1 (.A(A[1]), .B(B[1]^s),//wire  없이 바로 연결              
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
         //위에 comparator_N_bit모듈 이용해서 16비트 비교기 만들어
        
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
       
       else if ( A>B) begin       //else없으면 위에 조건 맞아도 밑에 조건 비교해봐,
            equal=0;              //  else있으면  위에 조건 맞을 때 else조건 실행 안해
            greater =1;
            less=0;
            
       end
       
       else begin    //if문 마지막에  else begin 없으면 latch회로 만들어지고, latch회로 만들면 안돼
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
    always @(code)begin     //begin end 생략 불가 -->구문 여러개
        if          (code==0) signal = 4'b0001;
        else if (code==2'b01) signal = 4'b0010;
        else if (code==2'b10) signal = 4'b0100;
        else                  signal = 4'b1000;
    end
endmodule

   
//    always @(code) begin        //begin end생략가능--> case문 한개라
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
    always @(code,enable)begin     //begin end 생략 불가 -->구문 여러개
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
//    or (f, w0,w1);//출력f

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