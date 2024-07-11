`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////


module fnd_4digit_cntr(
        input clk, reset_p,
        input [15:0] value,
        output [7:0] seg_7_an, seg_7_ca,
        output [3:0] com);
        
        reg [3:0] hex_value;
        
    ring_counter_fnd rc(.clk(clk), .reset_p(reset_p), .com(com));//���ֱ� �ӵ� �����ϸ� ��� �ȳ���_������?    

    always @(posedge clk) begin
        case(com)
            4'b0111: hex_value = value[15:12];
            4'b1011: hex_value = value[11:8];     
            4'b1101: hex_value = value[7:4];   
            4'b1110: hex_value = value[3:0];   
        endcase
    end    
  
    decoder_7seg fnd (.hex_value(hex_value), .seg_7(seg_7_an));   
    assign  seg_7_ca = ~seg_7_an;
    
    endmodule
///////////////////////////////////////////////////////
 module button_cntr(
        input clk, reset_p,
        input btn,
        output btn_pe, btn_ne);
        
        reg [16:0] clk_div;//������ =0 ����
        wire clk_div_16;   
        reg [1:0]debounced_btn;
       
        always @ (posedge clk)      clk_div = clk_div +1;
        edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .p_edge(clk_div_16));
      
        
        always @ (posedge clk, posedge reset_p) begin
            if(reset_p) debounced_btn=0;
            else if (clk_div_16) debounced_btn = btn;
        end   
         edge_detector_n ed2(.clk(clk), .reset_p(reset_p), 
                .cp(debounced_btn), .p_edge(btn_pe), .n_edge(btn_ne));
          
    endmodule    
    ///////////////////////////////////////////////////////////////////////
module key_pad_cntr(
    input clk, reset_p,
    input [3:0] row,
    output reg [3:0] col,
    output reg[3:0] key_value,
    output reg key_valid);

    reg [19:0] clk_div;
    always @(posedge clk) clk_div =clk_div +1;
    wire clk_8msec;
    wire clk_8msec_n;
    wire clk_8msec_p;

    edge_detector_n ed (.clk(clk), .reset_p(reset_p), .cp(clk_div[19]), .p_edge(clk_8msec_p), .n_edge(clk_8msec_n));
   
   
    always @(posedge clk or posedge reset_p) begin 
        if(reset_p) col = 4'b0001;
        else if(clk_8msec_p && !key_valid) begin
         case(col)
                4'b0001: col= 4'b0010;
                4'b0010: col= 4'b0100;
                4'b0100: col= 4'b1000;
                4'b1000: col= 4'b0001;
                default  col= 4'b0001;
            endcase   
         end
    end

    always @(posedge clk, posedge reset_p)begin
        if(reset_p)begin
            key_value = 0;
            key_valid = 0;
        end
        else begin
            if(clk_8msec_n)begin
            if(row)begin
                key_valid=1;
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
            else begin
                key_valid =0;
                key_value =0; //��� ������ �ՌH���� �� Ŭ����, ������ ����434 
            end
        end
    end
end
endmodule

/////////////////////
module dht11(
    input clk, reset_p,
    inout dht11_data,
    output reg [7:0] humidity, temperature,
    output [7:0] led_bar
    );
    parameter S_IDLE      = 6'b000001;
    parameter S_LOW_18MS  = 6'b000010;   //us�� 18000���� �״����
    parameter S_HIGH_20US = 6'b000100;
    parameter S_LOW_80US  = 6'b001000;
    parameter S_HIGH_80US = 6'b010000;
    parameter S_READ_DATA = 6'b100000;
    //shift �������͸� ���� ���� �����ؼ� ����� ����
    //6�� ���¶� 3��Ʈ �Ἥ 8���� ���¸� ������ ������
    //�׷��� ī���ͷ� �����ؾ��ؼ� �����
    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;

    reg [21:0] count_usec;
    wire clk_usec;
    reg count_usec_e;       //usec count enable
    clock_usec usec_clk(clk, reset_p, clk_usec);

    
    always @(negedge clk or posedge reset_p)begin       //usec 1�ֱ⸶�� ī���� ���� usec counter
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;         
        end
    end

    wire dht_pedge, dht_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(dht11_data), .p_edge(dht_pedge), .n_edge(dht_nedge));
    
    reg [5:0] state, next_state;
    reg [1:0] read_state;
    
    
    assign led_bar[5:0] = state;
    always @(negedge clk or posedge reset_p)begin   //���µǸ� idle��, �ƴϸ� next_stage
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end

    reg [39:0] temp_data;
    reg [5:0] data_count;   
    reg dht11_buffer;                    // inout ��Ʈ�� reg�ü� ���
    assign dht11_data = dht11_buffer;    //���۸��� ��������
    
 always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin            //���µǸ� usecī���� ����, idle�ΰ���, ����� �ڿ������� ���Ǵ����� ������, 
            count_usec_e = 0;
            next_state = S_IDLE;
            dht11_buffer = 1'bz;//���Ǵ��� ���, 1����ϰ� �ִµ� �ܺ���ġ 0�� ����Ǿ����� ���� Ȯ ����Ǽ� �ջ����� �� �־�
                                 // Ǯ�������־ �����ʹ� high�ɰ�
                                 //inout������ �׻� ���Ǵ��� ��� ���������            
            read_state = S_WAIT_PEDGE;
            data_count = 0; //������ �ʱ�ȭ                                           
        end        
        
         else begin //���� �ƴϸ�  ���� ����
            case(state)
                S_IDLE:begin    // idle�����ϰ� ���� �ɋ����� ī���� ������Ű�� ���Ǵ��� ��½���
                    if(count_usec <= 22'd3_000_000)begin //3_000_000
                        count_usec_e = 1;
                        dht11_buffer = 1'bz;
                    end
                    else begin //3�ʰ� ���� : ���� ������Ʈ �� �ѱ�� ī���� �ʱ�ȭ
                        next_state = S_LOW_18MS;
                        count_usec_e = 0;
                    end                    
                end

                S_LOW_18MS:begin    // MCU�ð� ������ �ּ� 18us �ð����� ��ȣ��(0-->Ǯ���̶�) 
                    if(count_usec <= 22'd20_000)begin //������ ��Ʈ�� �ּ� 22'd18_000 �ֶ��ؼ� �������̰� 20 ��
                        count_usec_e = 1;
                        dht11_buffer = 0;
                    end
                    else begin       
                    //���� �ּ� �ð������� ����������Ʈ, ī���� �ʱ�ȭ,, ���Ǵ����༭ ���� ������
                        count_usec_e = 0;
                        next_state = S_HIGH_20US;
                        dht11_buffer = 1'bz; //���Ǵ����� �༭ ������ ������
                    end
                end
                
                S_HIGH_20US:begin       //MCU������ �ð� �����ϱ� ���Ǵ����� ���������·� 20us 40us ��ٸ��� DHT�� �����Ұ���==> 
                   if(count_usec < 22'd20_000)begin
                        count_usec_e = 1;
                        dht11_buffer = 1'bz;
                        if(dht_nedge)begin  //DHT�� �����ؼ� 0��ȣ �ָ� nEDGE�� �����ؼ� ���� ������Ʈ�� �Ѿ�� ī���� �ʱ�ȭ
                            next_state = S_LOW_80US;
                            count_usec_e = 0;
                        end                           
                    end
                    else begin
                        next_state = S_IDLE;
                    end
                end
                
                S_LOW_80US:begin    //DHT�� ������ �������� �ϱ⸸ �ϸ� �� ==> EDGE������ �ϸ� ��
                    if(dht_pedge)begin  //������ DHT�� �����ؼ� 0���� ��ȣ �Z���ϱ� 1�ö󰡴� �� PEDGE�� �����ϸ� ��
                        next_state = S_HIGH_80US;   //�����ϸ� ���� �ܰ�
                    end
//                    else begin
//                        next_state = S_LOW_80US;
//                    end
                end
                S_HIGH_80US:begin   //80us���� ��ٸ��� ���۽��۽�ȣ �ΰ�(0)�Ǹ� == negedge �����Ǹ�  �����ܰ� �Ѿ
                    if(dht_nedge)begin
                        next_state = S_READ_DATA;
                    end
                end
                S_READ_DATA:begin
                    case(read_state)
                        S_WAIT_PEDGE:begin  //50us�� ���� ��ŸƮ ��ȣ�� ������, 
                            if(dht_pedge)begin
                                read_state = S_WAIT_NEDGE; //wait_nedge ���·� �ٲ�
                            end
                            count_usec_e = 0;
                        end
                        S_WAIT_NEDGE:begin  //  �����ϰ��ϱ� ���� ���� �ڵ�� ����, wait_nedge�� �ٲ��
                            if(dht_nedge)begin  //���� ���� �ϰ��ϸ� �������� �ð�ī���� ���� ���� 0,1�� temp_data�� �Է�
                                if(count_usec < 50)begin    // ������ ���۽��� ��ȣ
                                    temp_data = {temp_data[38:0], 1'b0};    //0
                                end
                                else begin                  //��Ʈ �Է�(����ġ off==1�� �ԷµǴ� �ð�) �ɶ�
                                    temp_data = {temp_data[38:0], 1'b1};    //1
                                end
                                data_count = data_count + 1;
                                read_state = S_WAIT_PEDGE;
                            end    
                            else begin
                                count_usec_e = 1;
                            end
                        end
                    endcase
                    if(data_count >= 40)begin
                        data_count = 0;
                        next_state = S_IDLE;
                        humidity = temp_data[39:32];
                        temperature = temp_data[23:16];
                    end
                    
                    
                    
                end
                default:next_state = S_IDLE;
            endcase
        end
    end
    
endmodule
////////////////////////////////////////////////////////////////

module sonic(
    input clk, reset_p,
    input echo,
    output trig,
    output [2:0] led_bar,
    output [11:0] distance_out
    );
    parameter IDLE = 3'b001;
    parameter TRIGGER = 3'b010;
    parameter ECHO_PULSE = 3'b100;
    
    parameter WAIT_PEDGE = 2'b01;
    parameter WAIT_NEDGE = 2'b10;
    
    reg [30:0] count_usec;
    wire clk_usec;
    reg count_usec_e;
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    always @(negedge clk or posedge reset_p)begin       //usec 1�ֱ⸶�� ī���� ���� usec counter
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;         
        end
    end

    wire echo_pedge, echo_nedge;
  
    edge_detector_n ed1(.clk(clk), .reset_p(reset_p), .cp(echo), .p_edge(echo_pedge), .n_edge(echo_nedge));
    
    reg [2:0] state, next_state;
    reg [1:0] read_state;
        
    assign led_bar[2:0] = state;
    
    always @(negedge clk or posedge reset_p)begin   //���µǸ� idle��, �ƴϸ� next_stage
        if(reset_p) state = IDLE;
        else state = next_state;
    end

     reg trig_buffer;
     reg [7:0] distance;
     assign trig =trig_buffer;                    // inout ��Ʈ�� reg�ü� ���
       //���۸��� ��������

     always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin            //���µǸ� usecī���� ����, idle�ΰ���, ����� �ڿ������� ���Ǵ����� ������, 
            count_usec_e = 0;
            next_state = IDLE;
            trig_buffer = 0;
            //���Ǵ��� ���, 1����ϰ� �ִµ� �ܺ���ġ 0�� ����Ǿ����� ���� Ȯ ����Ǽ� �ջ����� �� �־�
                                 // Ǯ�������־ �����ʹ� high�ɰ�
                                 //inout������ �׻� ���Ǵ��� ��� ���������            
            read_state = WAIT_PEDGE;  
            distance = 0;                                       
        end        

        else begin //���� �ƴϸ�  ���� ����
            case(state)
                IDLE:begin    // idle�����ϰ� ���� �ɋ����� ī���� ������Ŵ
                    if(count_usec <= 22'd100_000)begin 
                        count_usec_e = 1;
                        trig_buffer = 0;                       
                    end
                    else begin //3�ʰ� ���� : ���� ������Ʈ �� �ѱ�� ī���� �ʱ�ȭ
                        next_state = TRIGGER;
                        count_usec_e = 0;
                    end                    
                 end

                TRIGGER:begin    // MCU�ð� ������ �ּ� 10us �ð����� ��ȣ��
                    if(count_usec <= 22'd10)begin 
                        count_usec_e = 1;
                        trig_buffer = 1;
                    end
                    else begin       
                    //���� �ּ� �ð������� ����������Ʈ, ī���� �ʱ�ȭ,, 
                        count_usec_e = 0;
                        next_state = ECHO_PULSE;
                        trig_buffer = 0; 
                    end
                end            

//                SONIC_BURST:begin       // Ʈ���Ű� ����Ʈ ������ 
                  
//                        if(echo_pedge)begin  //DHT�� �����ؼ� 0��ȣ �ָ� nEDGE�� �����ؼ� ���� ������Ʈ�� �Ѿ�� ī���� �ʱ�ȭ
//                            next_state = ECHO_PULSE;
//                            count_usec_e = 0;
//                        end                           
                    
//                    else begin
//                        next_state = IDLE;
//                    end
//                end
                
                ECHO_PULSE:begin
                    case(read_state)
                        WAIT_PEDGE:begin  
                            if(echo_pedge)begin
                                 count_usec_e = 0;
                                 read_state = WAIT_NEDGE; //wait_nedge ���·� �ٲ�
                            end
                            
                        end
                        WAIT_NEDGE:begin  //  �����ϰ��ϱ� ���� ���� �ڵ�� ����, wait_nedge�� �ٲ��
                            if(echo_nedge)begin  //���� ���� �ϰ��ϸ� �������� �ð�ī���� ���� ���� 0,1�� temp_data�� �Է�
                                count_usec_e =0 ;
                                distance = count_usec/58 - 38; 
                                 next_state = IDLE;                                
                            end                                   
                            else begin    
                                count_usec_e =1;                               
                            end
                        end                      
                    endcase                  
                end
                default:next_state = IDLE;
            endcase
        end
    end
    assign distance_out = distance;
endmodule
////////////////////////////////////////////////////////////
module ultra_sonic_prof(
    input clk, reset_p,
    input echo, 
    output reg trigger,
    output reg [11:0] distance,
    output [3:0] led_bar
);
    
    parameter S_IDLE    = 3'b001;
    parameter TRI_10US  = 3'b010;
    parameter ECHO_STATE= 3'b100;
    
    parameter S_WAIT_PEDGE = 2'b01;
    parameter S_WAIT_NEDGE = 2'b10;
    
    reg [21:0] count_usec;
    wire clk_usec;
    reg count_usec_e;
    
    clock_usec usec_clk(clk, reset_p, clk_usec);
    
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) count_usec = 0;
        else begin
            if(clk_usec && count_usec_e) count_usec = count_usec + 1;
            else if(!count_usec_e) count_usec = 0;
        end
    end

    wire echo_pedge, echo_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(echo), .p_edge(echo_pedge), .n_edge(echo_nedge));
    
    reg [11:0] echo_time;
    reg [3:0] state, next_state;
    reg [1:0] read_state;
    
       reg cnt_e;
       wire [11:0] cm;
       sr04_div58 div58(clk, reset_p, clk_usec, cnt_e, cm);
       
    
    assign led_bar[3:0] = state;

    always @(negedge clk or posedge reset_p)begin
        if(reset_p) state = S_IDLE;
        else state = next_state;
    end
    
    always @(posedge clk or posedge reset_p)begin   // always @(posedge clk_usec or posedge reset_p)begin
                                                         //usec�� �÷� ������ �༭ negative slack ����
                                                         //������ �񵿱� ȸ�ΰ� ��
                                                         //���� always��, ���� always���� ���� �ٸ� �ø��÷� ���
        if(reset_p)begin
            count_usec_e = 0;
            next_state = S_IDLE;
            trigger = 0;
            read_state = S_WAIT_PEDGE;
        end
        else begin
            case(state)
                S_IDLE:begin
                    if(count_usec < 22'd100_000)begin 
                        count_usec_e = 1; 
                    end
                    else begin 
                        next_state = TRI_10US;
                        count_usec_e = 0; 
                    end
                end
                TRI_10US:begin 
                    if(count_usec <= 22'd10)begin 
                        count_usec_e = 1;
                        trigger = 1;
                    end
                    else begin
                        count_usec_e = 0;
                        trigger = 0;
                        next_state = ECHO_STATE;
                    end
                end
                ECHO_STATE:begin 
                    case(read_state)
                        S_WAIT_PEDGE:begin
                            count_usec_e = 0;
                            if(echo_pedge)begin
                                read_state = S_WAIT_NEDGE;
                                cnt_e = 1;  //�߰�
                            end
                        end
                        S_WAIT_NEDGE:begin
                            if(echo_nedge)begin       
                                read_state = S_WAIT_PEDGE;
                                count_usec_e = 0;                    
                                distance = cm;  //�߰�
                                cnt_e =0;       //�߰�
                                next_state = S_IDLE;
                            end
                            else begin
                                count_usec_e = 1;
                            end
                        end
                    endcase
                end
                default:next_state = S_IDLE;
            endcase
        end
    end
//    always @(posedge clk or posedge reset_p) begin
//        if(reset_p) distance = 0;
//        else begin
//            distance = echo_time / 58;
//             if(echo_time < 58) distance = 0;
//             else if(echo_time < 116) distance = 1;
//                else if(echo_time < 174) distance = 2;
//                else if(echo_time < 232) distance = 3;
//                else if(echo_time < 290) distance = 4;
//                else if(echo_time < 348) distance = 5;
//                else if(echo_time < 406) distance = 6;
           
//        end
//    end    
    
endmodule
//////////////////////////////////////////////////////////
module pwm_100pc(
    input clk, reset_p,
    input [6:0] duty,
    input [13:0]pwm_freq,
    output reg pwm_100pc
    );
    parameter sys_clk_freq = 100_000_000; //125_000_000  //pwm_freq ������ sys_clk_freq ������� ���� 1, ���� 0
    
    reg[26:0] cnt;
    reg pwm_freqX100;
    
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            pwm_freqX100 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= sys_clk_freq / (pwm_freq *100) - 1) cnt = 0;
            else cnt = cnt + 1;
                
            if(cnt < sys_clk_freq / pwm_freq / 100/2) pwm_freqX100 = 0;
            else pwm_freqX100 = 1;
        end              
    end
   
    wire pwm_freqX100_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX100),.n_edge(pwm_freqX100_nedge));
    
    reg [6:0] cnt_duty;
   
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_duty = 0;
            pwm_100pc = 0;            
        end
        else begin
            if(pwm_freqX100_nedge) begin
                if(cnt_duty >= 99) cnt_duty = 0;    //100�� ī���Ͱ� ���� ������ ��Ƽ������ ������ 0 ������ 1
                else cnt_duty = cnt_duty + 1;
                
                if(cnt_duty < duty) pwm_100pc = 1;
                else pwm_100pc = 0;
            end
            else begin
            
            end        
        end
    end   
endmodule 
//////////////////////////////////////////////////////////////
module pwm_128step(
    input clk, reset_p,
    input [6:0] duty,
    input [13:0]pwm_freq,
    output reg pwm_128
    );
    parameter sys_clk_freq = 100_000_000; //125_000_000  
    
    reg[26:0] cnt;
    reg pwm_freqX128;
    
    wire [26:0]temp; //100_000_000 ������   
   
    integer cnt_sysclk;
    assign temp = sys_clk_freq/pwm_freq;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            pwm_freqX128 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[26:7] - 1) cnt = 0;//�߶� ������ == shift����,,, �ݴ�� 0 �߰�
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
            else begin
            
            end        
        end
    end   
endmodule   
//////////////////////////////////////////////////////////////////////
module pwm_512step(
    input clk, reset_p,
    input [8:0] duty, 
    input [13:0]pwm_freq,
    output reg pwm_512
    );
    parameter sys_clk_freq = 100_000_000; //125_000_000  
    
    reg[26:0] cnt;
    reg pwm_freqX512;
    
    wire [31:0]temp; //100_000_000 ������   
   
    integer cnt_sysclk;
    assign temp = sys_clk_freq/pwm_freq;

    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            pwm_freqX512 = 0;
            cnt = 0;
        end
        else begin
            if(cnt >= temp[27:9] - 1) cnt = 0;//�߶� ������ == shift����,,, �ݴ�� 0 �߰�
            else cnt = cnt + 1;
                
            if(cnt <temp[27:10]) pwm_freqX512 = 0;
            else pwm_freqX512 = 1;
        end               
    end
   
    wire pwm_freqX512_nedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(pwm_freqX512),.n_edge(pwm_freqX512_nedge));
    
    reg [8:0] cnt_duty;
   
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_duty = 0;
            pwm_512 = 0;            
        end
        else begin
            if(pwm_freqX512_nedge) begin
                                                   
                cnt_duty = cnt_duty + 1;
                
                if(cnt_duty < duty) pwm_512 = 1;
                else pwm_512 = 0;
            end                   
        end
    end   
endmodule   
///////////////////////////////////////////////////
module pwm_512_period(
    input clk, reset_p,
    input [21:0] duty,
    input [21:0]pwm_period,
    output reg pwm_512
    );   
  
    reg [21:0] cnt_duty; // top��⿡�� �ֱ⿡ 2000000�� �༭ �̸�ŭ ��Ʈ �ʿ�
   
    always @(posedge clk or posedge reset_p) begin
        if(reset_p) begin
            cnt_duty = 0;
            pwm_512 = 0;            
        end
        else begin
            if(cnt_duty >= pwm_period) cnt_duty = 0;
            else cnt_duty = cnt_duty +1;              
                if(cnt_duty < duty) pwm_512 = 1;
                else pwm_512 = 0;
            end                   
        end
endmodule   
/////////////////////////////////////////////////////////////////////////

module I2C_master(
    input clk, reset_p,
    input rd_wr,
    input [6:0] addr,//���⸸�ҰŶ� output ����
    input [7:0] data,
    input valid,
    output reg sda,
    output reg scl  // �б⵵ �ҰŸ�  inout��
);

    parameter IDLE =        7'b000_0001;
    parameter COMM_START =  7'b000_0010;    //communication start
    parameter SND_ADDR =    7'b000_0100;     //SEND ADDRESS
    parameter RD_ACK =      7'b000_1000;
    parameter SND_DATA =    7'b001_0000;
    parameter SCL_STOP =    7'b010_0000;
    parameter COMM_STOP =   7'b100_0000;
    
    wire [7:0] addr_rw;
    assign addr_rw = {addr, rd_wr};
    
    wire clk_usec;
    clock_usec usec_clk(clk, reset_p, clk_usec);   //1Mhz�� �ʹ� ���� count_usec5
    
    reg [2:0] count_usec5;
    reg scl_toggle_e;
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            count_usec5 = 0;
            scl = 1;
        end
        else if(scl_toggle_e)begin
            if(clk_usec)begin
                if(count_usec5 >= 4)begin
                    count_usec5 = 0;
                    scl = ~scl;
                end
                else count_usec5 = count_usec5 + 1;
            end     
        end
        else if(scl_toggle_e == 0) count_usec5 = 0;
    end
     
    wire scl_nedge, scl_pedge;
    edge_detector_n ed(.clk(clk), .reset_p(reset_p), .cp(scl), .n_edge(scl_nedge), .p_edge(scl_pedge));   
    
    wire valid_pedge;
    edge_detector_n ed_valid(.clk(clk), .reset_p(reset_p), .cp(valid), .p_edge(valid_pedge));
    
    reg [6:0] state, next_state;
    always @(negedge clk or posedge reset_p)begin
        if(reset_p)state = IDLE;
        else state = next_state;
    end
    
    reg [2:0] cnt_bit;  //SND_ADDR���� addr_rw �ϰ��������� 7~0����Ʈ ���� �ϱ����� ī���� �̿��Ϸ���
    reg stop_data;  //// RD_ACK --> SND_DATA --> RD_ACT or SCL_STOP
    
    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            sda = 1;  // �ʱⰪ sdl,scl == high
            next_state = IDLE;
            scl_toggle_e = 0; //0�̸� ��� ����
            cnt_bit = 7; //7���� �����ؼ� �Ʒ���
            stop_data = 0;
        end
        else begin
            case(state)
                IDLE:begin
                    if(valid_pedge)next_state = COMM_START;
                end
                COMM_START:begin
                    sda = 0; //LOW�� �����鼭  start
                    scl_toggle_e = 1;
                    next_state = SND_ADDR;
                end
                SND_ADDR:begin
                    if(scl_nedge)sda = addr_rw[cnt_bit];    //scl�ϰ��������� 7����Ʈ~0����Ʈ ��
                    else if(scl_pedge)begin
                        if(cnt_bit == 0)begin 
                            cnt_bit = 7;
                            next_state = RD_ACK;
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end
                RD_ACK:begin //Master���� 8��Ʈ�� �ּ�, rw���Ե� �����͸� ������ ��.
                             // slave���� ACK��ȣ �ִ°� �޾ƾ� ������ �ȹް� �׳� �ð��� �Ҵ� 
                    if(scl_nedge) sda = 'bz;
                    else if(scl_pedge)begin
                        if(stop_data)begin
                            stop_data = 0;
                            next_state = SCL_STOP;
                        end
                        else begin
                            next_state = SND_DATA;
                        end
                    end
                end
                SND_DATA:begin
                    if(scl_nedge)sda = data[cnt_bit];  //scl�ϰ��������� 7����Ʈ~0����Ʈ ��
                    else if(scl_pedge)begin
                        if(cnt_bit == 0)begin 
                            cnt_bit = 7;                 //�Ƚᵵ 0���� 1���� 7 ��
                            next_state = RD_ACK;
                            stop_data = 1;                            
                        end
                        else cnt_bit = cnt_bit - 1;
                    end
                end    
                SCL_STOP:begin              //�켱 SDA�� 0���� ����� SCL�� 1���ϸ� STOP
                     if(scl_nedge)begin
                        sda = 0;
                     end
                     else if(scl_pedge)begin                       
                        next_state = COMM_STOP;
                     end
                end
                COMM_STOP:begin
                    if(count_usec5 >= 3)begin
                        sda = 1;
                        scl_toggle_e = 0; //Ŭ�� ����
                        next_state = IDLE;
                    end
                end
            endcase
        end
    end    
endmodule
////////////////////////////////////////////////
module i2c_lcd_send_byte(
    input clk, reset_p,
    input [6:0] addr,
    input [7:0] send_buffer,    // �츮�� ���� 4��Ʈ
    input send, rs,
    output scl, sda,
    output reg busy);

    parameter IDLE                     = 6'b00_0001;
    parameter SEND_HIGH_NIBBLE_DISABLE = 6'b00_0010;
    parameter SEND_HIGH_NIBBLE_ENABLE  = 6'b00_0100;
    parameter SEND_LOW_NIBBLE_DISABLE  = 6'b00_1000;
    parameter SEND_LOW_NIBBLE_ENABLE   = 6'b01_0000;
    parameter SEND_DISABLE             = 6'b10_0000;

    reg [7:0] data;
    reg valid;
    reg [21:0] count_usec; // ������ �۵��ϴ� LCD - time�� �����
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
 
    wire send_pedge; // send�� edge detect(����)
    edge_detector_n ed_i2c(.clk(clk), .reset_p(reset_p), 
        .cp(send), .p_edge(send_pedge));

    reg [5:0] state, next_state; //fsm
    always @(negedge clk or posedge reset_p)begin
        if(reset_p) state = IDLE;
        else state = next_state;
    end

    always @(posedge clk or posedge reset_p)begin
        if(reset_p)begin
            next_state = IDLE;
            busy = 0;
        end
        else begin
            case(state)
                IDLE: begin
                    if(send_pedge)begin
                        next_state = SEND_HIGH_NIBBLE_DISABLE;
                        busy = 1;
                    end
                end

                SEND_HIGH_NIBBLE_DISABLE: begin
                    if(count_usec <= 22'd200)begin   // deximal 200us
                        data = {send_buffer[7:4], 3'b100, rs}; // {d7 d6 d5 d4 ,BT, E, RW, rs}
                        valid = 1;
                        count_usec_e = 1;   // 200us wait
                    end
                    else begin
                        next_state = SEND_HIGH_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end // high 8bit data ���ư�
                end

                SEND_HIGH_NIBBLE_ENABLE: begin
                    if(count_usec <= 22'd200)begin   // deximal 200us
                        data = {send_buffer[7:4], 3'b110, rs}; // {d7 d6 d5 d4 ,BT, E, RW, rs}
                        valid = 1;
                        count_usec_e = 1;   // 200us wait
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_DISABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end // high 8bit data �Ѿ
                end

                SEND_LOW_NIBBLE_DISABLE: begin
                    if(count_usec <= 22'd200)begin   // deximal 200us
                        data = {send_buffer[3:0], 3'b100, rs}; // {d7 d6 d5 d4 ,BT, E, RW, rs}
                        valid = 1;
                        count_usec_e = 1;   // 200us wait
                    end
                    else begin
                        next_state = SEND_LOW_NIBBLE_ENABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end // low 8bit data ���ư�
                end

                SEND_LOW_NIBBLE_ENABLE: begin
                    if(count_usec <= 22'd200)begin   // deximal 200us
                        data = {send_buffer[3:0], 3'b110, rs}; // {d7 d6 d5 d4 ,BT, E, RW, rs}
                        valid = 1;
                        count_usec_e = 1;   // 200us wait
                    end
                    else begin
                        next_state = SEND_DISABLE;
                        count_usec_e = 0;
                        valid = 0;
                    end // low 8bit data �Ѿ
                end

                SEND_DISABLE: begin // disable�� �ٲ������(e)
                    if(count_usec <= 22'd200)begin   // deximal 200us
                        data = {send_buffer[3:0], 3'b100, rs}; // {d7 d6 d5 d4 ,BT, E, RW, rs}
                        valid = 1;
                        count_usec_e = 1;   // 200us wait
                    end
                    else begin
                        next_state = IDLE;
                        count_usec_e = 0;
                        valid = 0;
                        busy = 0;
                    end
                end
            endcase
        end
    end

    I2C_master master(.clk(clk), .reset_p(reset_p),
        .rd_wr(0), .addr(7'h27), .data(data), .valid(valid),
        // .led_bar(led_bar), 
        .sda(sda), .scl(scl));
endmodule
///
module joystick(
        input clk, reset_p,
        input vauxp6, vauxn6,
        input vauxp15, vauxn15,
        output reg [11:0] value_x, value_y
);

        wire [4:0] channel_out;
        wire [15:0] do_out;
        wire eoc_out, eoc_out_pedge;


        xadc_wiz_0 adc_joystick
          (
          .daddr_in({2'b0, channel_out}),            // Address bus for the dynamic reconfiguration port
          .dclk_in(clk),             // Clock input for the dynamic reconfiguration port
          .den_in(eoc_out),              // Enable Signal for the dynamic reconfiguration port
          .vauxp6(vauxp6),              // Auxiliary channel 6
          .vauxn6(vauxn6),
          .vauxp15(vauxp15),             // Auxiliary channel 15
          .vauxn15(vauxn15),
          .channel_out(channel_out),         // Channel Selection Outputs
          .do_out(do_out),              // Output data bus for dynamic reconfiguration port
          .eoc_out(eoc_out),             // End of Conversion Signal
          .eos_out(eos_out)             // End of Sequence Signal
          );

          edge_detector_n ed_timeout(.clk(clk), .reset_p(reset_p), .cp(eoc_out), .p_edge(eoc_out_pedge)); 

            always @(posedge clk or posedge reset_p)begin
                    if(reset_p)begin
                            value_x = 0;
                            value_y = 0;
                    end
                    else if (eoc_out_pedge)begin
                            case(channel_out[3:0])
                                    6: value_y =  {do_out[15:9]}; //2 4 8 16 32 64 �ִ� 127���� 
                                    15 : value_x =  {do_out[15:9]}; //
                            endcase
                    end
            end
endmodule