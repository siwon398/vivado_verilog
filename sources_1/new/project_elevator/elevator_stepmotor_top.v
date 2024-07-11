`timescale 1ns / 1ps
//////////////////////////////////////////////////
module elevator_sub(
    input clk, reset_p,
    input [3:0] btn,
    output reg [3:0] motorpin
);
    parameter STEP_PER_REVOLUTION = 4096;
    parameter DEGREE = 1030;
    

    reg [2:0] step;
    reg [15:0] step_counter;
    reg [23:0] delay_counter;  
    reg step_active;
    reg direction; 
    reg [1:0] current_floor; // 0:1√˛, 1:2√˛, 2:3√˛
    
    wire [3:0] btn_pedge;
    reg [15:0] action_steps;
    reg [1:0] btn_val;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[2]));
    button_cntr btn_cntr3(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pe(btn_pedge[3]));
    
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            step = 3'd0;
            step_counter = 0;
            delay_counter = 0;
            step_active = 0;
            direction = 0;
            current_floor = 2'd0;
            action_steps = 0;
            btn_val = 0;
        end 
        else begin  ///πˆ∆∞ øß¡ˆ ºˆ∏∏≈≠ √ﬂ∞°«ÿ ¡÷∏È ¥Ô
            if (btn_pedge[0]) begin
                btn_val = 2'd0;
            end 
            else if (btn_pedge[1]) begin
                btn_val = 2'd1;
            end 
            else if (btn_pedge[2]) begin
                btn_val = 2'd2;
            end 
            else if (btn_pedge[3]) begin
                btn_val = 2'd3;  
            end
        
        
            if (btn_pedge[0] || btn_pedge[1] || btn_pedge[2] || btn_pedge[3]) begin//πˆ∆∞ øß¡ˆ ºˆ∏∏≈≠ √ﬂ∞°«ÿ ¡÷∏È ¥Ô
                if (btn_val != current_floor) begin
                    step_active = 1;
                    direction = ((btn_val > current_floor) ? 0 : 1);
                    action_steps = (DEGREE * STEP_PER_REVOLUTION * ((btn_val > current_floor) ? (btn_val - current_floor) : (current_floor - btn_val))) / 360;
                    current_floor = btn_val;
                end
                else if (btn_val == current_floor) begin
                    step_active = 0;
                end
            end
            
            if(step_active)begin
                if (delay_counter < 24'd75000)begin
                    delay_counter = delay_counter + 1; // 800us
                end
                else begin
                    delay_counter = 24'd0;
                    if(step_counter < action_steps)begin
                        if(direction == 0)begin
                            step = (step + 1) % 8;
                        end
                        else begin
                            step = (step - 1) % 8;
                        end
                        step_counter = step_counter + 1;
                    end
                    else if ( direction ==1) begin  
                        step_active = 0;
                        step_counter = 0;
                    end
                end 
            end
        end
    end
    
    always @(posedge clk)begin
        if(reset_p) begin
            motorpin = 4'b0000;
        end
        else begin
            case (step)
                3'd0: motorpin = 4'b1000;
                3'd1: motorpin = 4'b1100;
                3'd2: motorpin = 4'b0100;
                3'd3: motorpin = 4'b0110;
                3'd4: motorpin = 4'b0010;
                3'd5: motorpin = 4'b0011;
                3'd6: motorpin = 4'b0001;
                3'd7: motorpin = 4'b1001;
                default: motorpin = 4'b0000;
            endcase
        end
    end
endmodule

//////////////////////////////////////////////////
module stepmotor(
    input clk, reset_p,
    input [2:0] btn,
    output reg [3:0] motorpin
);
    parameter STEP_PER_REVOLUTION = 4096;
    parameter DEGREE_ONE = 1030;
    parameter DEGREE_TWO = 2060;

    reg [2:0] step;
    reg [15:0] step_counter;
    reg [23:0] delay_counter;  // Assuming a certain clock frequency, e.g., 50MHz for 800us delay
    reg step_active = 0;
    reg direction; 
    reg [1:0] current_floor; // 0:1√˛, 1:2√˛, 2:3√˛
    
    wire [2:0] btn_pedge;
    reg [15:0] action_steps;
    wire btn_en0,btn_en1,btn_en2;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn_en0), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn_en1), .btn_pe(btn_pedge[1]));
    button_cntr btn_cntr2(.clk(clk), .reset_p(reset_p), .btn(btn_en2), .btn_pe(btn_pedge[2]));
    
    
    
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            step <= 3'd0;
            step_counter <= 0;
            delay_counter <= 0;
            step_active <= 0;
            direction <= 0;
            current_floor <= 2'd0;
        end 
        else begin
        if(btn_pedge[0] && current_floor == 2'd1) begin  // 2√˛ø°º≠ 1√˛¿∏∑Œ
                step_active <= 1;
                direction <= 1;
                action_steps <= (DEGREE_ONE * STEP_PER_REVOLUTION) / 360;
                current_floor <= 2'd0;
            end
            else if(btn_pedge[1] && current_floor == 2'd0) begin  // 1√˛ø°º≠ 2√˛¿∏∑Œ
                step_active <= 1;
                direction <= 0;
                action_steps <= (DEGREE_ONE * STEP_PER_REVOLUTION) / 360;
                current_floor <= 2'd1;
            end
            else if(btn_pedge[2] && current_floor == 2'd1) begin  // 2√˛ø°º≠ 3√˛¿∏∑Œ
                step_active <= 1;
                direction <= 0;
                action_steps <= (DEGREE_ONE * STEP_PER_REVOLUTION) / 360;
                current_floor <= 2'd2;
            end
            else if(btn_pedge[1] && current_floor == 2'd2) begin  // 3√˛ø°º≠ 2√˛¿∏∑Œ
                step_active <= 1;
                direction <= 1;
                action_steps <= (DEGREE_ONE * STEP_PER_REVOLUTION) / 360;
                current_floor <= 2'd1;
            end
            else if(btn_pedge[2] && current_floor == 2'd0) begin  // 1√˛ø°º≠ 3√˛¿∏∑Œ
                step_active <= 1;
                direction <= 0;
                action_steps <= (DEGREE_TWO * STEP_PER_REVOLUTION) / 360;
                current_floor <= 2'd2;
            end
            else if(btn_pedge[0] && current_floor == 2'd2) begin  // 3√˛ø°º≠ 1√˛¿∏∑Œ
                step_active <= 1;
                direction <= 1;
                action_steps <= (DEGREE_TWO * STEP_PER_REVOLUTION) / 360;
                current_floor <= 2'd0;
            end
            
            if(step_active)begin
                if (delay_counter < 24'd75000)begin
                    delay_counter <= delay_counter + 1; // 800us
                end
                else begin
                    delay_counter <= 24'd0;
                    if(step_counter < action_steps)begin
                        if(direction == 0)begin
                            step <= (step + 1) % 8;
                        end
                        else begin
                            step <= (step - 1) % 8;
                        end
                        step_counter <= step_counter + 1;
                    end
                    else begin  
                        step_active <= 0;
                        step_counter <= 0;
                    end
                end 
            end
        end
    end
    
    always @(posedge clk)begin
        if(reset_p) begin
            motorpin <= 4'b0000;
        end
        else begin
            case (step)
                3'd0: motorpin <= 4'b1000;
                3'd1: motorpin <= 4'b1100;
                3'd2: motorpin <= 4'b0100;
                3'd3: motorpin <= 4'b0110;
                3'd4: motorpin <= 4'b0010;
                3'd5: motorpin <= 4'b0011;
                3'd6: motorpin <= 4'b0001;
                3'd7: motorpin <= 4'b1001;
                default: motorpin <= 4'b0000;
            endcase
        end
    end
    assign btn_en0 = step_active ? 0 : btn[0];  //πˆ∆∞ ∫Ì∂Ù
    assign btn_en1 = step_active ? 0 : btn[1];
    assign btn_en2 = step_active ? 0 : btn[2];
endmodule

/////////////////////////////////////////////////


///////////////////////////////

module elevator_top(
    input clk, reset_p,
    input [1:0] btn,
    output [3:0] motorpin
);
    reg en_up=0
    , en_down=0;
    wire [3:0] motorpin_up, motorpin_down;
    reg [15:0] cnt1=0;
    reg [15:0] cnt2=0;
    wire [1:0] btn_pedge;
    
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    
  

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin            
            en_up = 0;
            en_down = 0;
        end
        else if (btn_pedge[0]) begin
            if(cnt1>=5) begin              
                en_up =0;
                en_down = 0;
                cnt1=0;
            end
            else begin
                cnt1 = cnt1+ 1;
                en_down = 0;
                en_up = 1;
                           
            end    
        end
        else if (btn_pedge[1]) begin
            
            if(cnt2>=100) begin
            en_up =0;
                en_down =0;
                cnt2=0;
            end
            else begin
            cnt2 = cnt2 + 1;
                en_up = 0;
                en_down = 1;
                
                 // en_down ∫Ò»∞º∫»≠
            end    
        end
       
        
    end

    stepmotor_up ele_up(
        .clk(clk),
        .reset_p(reset_p),
        .en(en_up),
        .motorpin(motorpin_up)
    );
    stepmotor_down ele_down(
        .clk(clk),
        .reset_p(reset_p),
        .en(en_down),
        .motorpin(motorpin_down)
    );

    // motorpin¿« ¥Ÿ¡ﬂ»≠ ≥Ì∏Æ √ﬂ∞°
    assign motorpin = en_up ? motorpin_up : en_down ? motorpin_down : 4'b0000;

endmodule
///////////////////////////////////////////////
module stepmotor_up(
    input clk, reset_p,
    input en,
    
    output reg [3:0] motorpin
);

    parameter STEP_PER_REVOLUTIN = 4096;
    parameter DEGREE = 360;
   
    
    reg [2:0] step;
    reg [15:0] step_counter=0;
    reg [23:0] delay_counter=0;  // Assuming a certain clock frequency, e.g., 50MHz for 800us delay
    reg step_active;

    wire [15:0] calculated_steps;

    assign calculated_steps = (DEGREE * STEP_PER_REVOLUTIN) / 360;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            step <= 3'd0;
            step_counter <= 16'd0;
            delay_counter <= 24'd0;
            step_active <= 1'b0;
            motorpin <= 4'b0000;
            
        end
        
        else if (en) begin
            if (delay_counter < 24'd80000)  // Adjust based on clock frequency for 800us delay
                delay_counter <= delay_counter + 1;
            else begin
                delay_counter <= 24'd0;
                step_counter <= step_counter + 1;
                step <= step + 1;             
            end
        end
        else  begin
            step <= 3'd0;
            step_counter <= 16'd0;
            delay_counter <= 24'd0;
            step_active <= 1'b0;
            motorpin <= 4'b0000;
        end
        case (step)
                3'd0: motorpin <= 4'b1000;
                3'd1: motorpin <= 4'b1100;
                3'd2: motorpin <= 4'b0100;
                3'd3: motorpin <= 4'b0110;
                3'd4: motorpin <= 4'b0010;
                3'd5: motorpin <= 4'b0011;
                3'd6: motorpin <= 4'b0001;
                3'd7: motorpin <= 4'b1001;
                default: motorpin <= 4'b0000;
        endcase
    end
endmodule
/////////////////////////////////////////////////////////////////////////
module stepmotor_down(
    input clk, reset_p,
    input en,
    
    output reg [3:0] motorpin
);

    parameter STEP_PER_REVOLUTIN = 4096;
    parameter DEGREE = 360;
   
    
    reg [2:0] step;
    reg [15:0] step_counter;
    reg [23:0] delay_counter;  // Assuming a certain clock frequency, e.g., 50MHz for 800us delay
    reg step_active;

    wire [15:0] calculated_steps;

    assign calculated_steps = (DEGREE * STEP_PER_REVOLUTIN) / 360;

    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            step <= 3'd0;
            step_counter <= 16'd0;
            delay_counter <= 24'd0;
            step_active <= 1'b0;
            motorpin <= 4'b0000;
            
        end
        else if (en ==0) begin
            step <= 3'd0;
            step_counter <= 16'd0;
            delay_counter <= 24'd0;
            step_active <= 1'b0;
            motorpin <= 4'b0000;
        end
        else if (en == 1) begin
            if (delay_counter < 24'd80000)  // Adjust based on clock frequency for 800us delay
                delay_counter <= delay_counter + 1;
            else begin
                delay_counter <= 24'd0;
                step_counter <= step_counter + 1;           
                step <= step - 1;
            end
        end
        case (step)
                3'd0: motorpin <= 4'b1000;
                3'd1: motorpin <= 4'b1100;
                3'd2: motorpin <= 4'b0100;
                3'd3: motorpin <= 4'b0110;
                3'd4: motorpin <= 4'b0010;
                3'd5: motorpin <= 4'b0011;
                3'd6: motorpin <= 4'b0001;
                3'd7: motorpin <= 4'b1001;
                default: motorpin <= 4'b0000;
        endcase
    end
endmodule
//////////////////////////////////////////////////////
module stepmotor_sj(
    input clk, reset_p,
    input [1:0] btn,
    output reg [3:0] motorpin
);
    parameter STEP_PER_REVOLUTIN = 4096;
    parameter DEGREE = 180;
    reg [2:0] step;
    reg [15:0] step_counter;
    reg [23:0] delay_counter;  // Assuming a certain clock frequency, e.g., 50MHz for 800us delay
    reg step_active = 0;
    wire [1:0] btn_pedge;
    wire [15:0] action_steps;
    button_cntr btn_cntr0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pe(btn_pedge[0]));
    button_cntr btn_cntr1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pe(btn_pedge[1]));
    assign action_steps = (DEGREE * STEP_PER_REVOLUTIN) / 360;
    always @(posedge clk or posedge reset_p) begin
        if (reset_p) begin
            step <= 3'd0;
            step_counter <= 0;
            delay_counter <= 0;
            step_active <= 0;
        end
        else begin
        if(btn_pedge[0])begin
            step_active <= 1;
        end
            if(step_active)begin
                if (delay_counter < 24'd80000)begin
                    delay_counter <= delay_counter + 1; // 800us
                end
                else begin
                    delay_counter <= 24'd0;
                    if(step_counter < action_steps)begin
                        step <= step + 1;
                        step_counter <= step_counter + 1;
                    end
                    else begin
                        step_active = 0;
                        step_counter = 0;
                    end
                end
            end
        end
    end
    always @(posedge clk)begin
        if(reset_p) begin
            motorpin <= 4'b0000;
        end
        else begin
            case (step)
                3'd0: motorpin <= 4'b1000;
                3'd1: motorpin <= 4'b1100;
                3'd2: motorpin <= 4'b0100;
                3'd3: motorpin <= 4'b0110;
                3'd4: motorpin <= 4'b0010;
                3'd5: motorpin <= 4'b0011;
                3'd6: motorpin <= 4'b0001;
                3'd7: motorpin <= 4'b1001;
                default: motorpin <= 4'b0000;
            endcase
        end
    end
endmodule