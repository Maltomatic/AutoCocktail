module drinkinator(
    input clk,
    input rst,
    inout PS2_CLK,
    inout PS2_DATA,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync,
    output reg [5:0] LED,
    output [6:0] _led,
    output reg dbg,
    output reg dbg2,
    output [6:0] DISPLAY,
    output [3:0] DIGIT,
    output m_wh, m_vo, m_ly, m_li, m_le, m_wa, st,
    output pwm,
    output reg st_pwm
);
    reg [9:0] p_max;
    always@(posedge clk) begin
        if(rst) begin
            p_max = 1000;
            st_pwm = 0;
        end else begin
            if(!p_max) p_max = 1000;
            else p_max = p_max-1;

            if(p_max > 400) st_pwm = 1;
            else st_pwm = 0;
        end
    end

    // mixer signals
    reg [2:0] drink;
    reg [3:0] custom_size;
    reg [3:0] c_wh, c_vo, c_ly, c_li, c_le, c_wa;
    wire bar_en;
    wire [1:0] status;
    wire done;
    mixer bartender(bar_en, rst, clk, drink[2:0], c_wh, c_vo, c_ly, c_li, c_le, c_wa, status, m_wh, m_vo, m_ly, m_li, m_le, m_wa, st, done);
    assign pwm = 1'b1;

    assign _led[6] = (status == 2'b00)? 1'b1: 1'b0;
    assign _led[5] = (status == 2'b01)? 1'b1: 1'b0;
    assign _led[4] = (status == 2'b10)? 1'b1: 1'b0;
    assign _led[3] = (status == 2'b11)? 1'b1: 1'b0;

    // keyboard signals
    wire [511:0]key_down;
    wire [8:0]last_change;
    wire key_valid;
    KeyboardDecoder kD(key_down, last_change, key_valid, PS2_DATA, PS2_CLK, rst, clk);
    parameter k0 = 9'h70, k1 = 9'h69, k2 = 9'h72, k3 = 9'h7A, k4 = 9'h6B, k5 = 9'h73, k6 = 9'h74, k7 = 9'h6C, k8 = 9'h75, k9 = 9'h7D,
              etr = {1'b0, 8'h5A};

    // FSM signals
    reg [1:0] state = 0;
    parameter order = 2'b00, customize = 2'b01, start = 2'b10;

    assign _led[2] = (state == order)? 1'b1: 1'b0;
    assign _led[1] = (state == customize)? 1'b1: 1'b0;
    assign _led[0] = (state == start)? 1'b1: 1'b0;

    //main_screen(clk, rst, state, last_change, key_valid, key_down, vgaRed, vgaGreen, vgaBlue, hsync, vsync);
    main_screen(clk, rst, state, drink, vgaRed, vgaGreen, vgaBlue, hsync, vsync);

    // drink FSM
    always@(posedge clk, posedge rst) begin
        if(rst) begin
            LED = 0;
            state = order;
            drink = 0;
            c_wh = 0;
            c_vo = 0;
            c_ly = 0;
            c_li = 0;
            c_le = 0;
            c_wa = 0;
        end else begin
            case(state)
                order: begin
                    LED = 0;
                    drink = drink;
                    state = order;
                    c_wh = 0;
                    c_vo = 0;
                    c_ly = 0;
                    c_li = 0;
                    c_le = 0;
                    c_wa = 0;
                    if(key_valid) begin
                        state = order;
                        case(last_change)
                            k1: if(key_down[last_change]) drink = 1;
                            k2: if(key_down[last_change]) drink = 2;
                            k3: if(key_down[last_change]) drink = 3;
                            k4: if(key_down[last_change]) drink = 4;
                            k5: if(key_down[last_change]) drink = 5;
                            k6: if(key_down[last_change]) drink = 6;
                            etr: if(key_down[last_change]) begin
                                if(drink == 6) begin
                                    state = customize;
                                    LED = 6'b100000;
                                end else if(drink != 0) state = start;
                                else state = order;
                            end
                        endcase
                    end
                end
                customize: begin
                    drink = 6;
                    LED = LED;
                    state = customize;
                    c_wh = c_wh;
                    c_vo = c_vo;
                    c_ly = c_ly;
                    c_li = c_li;
                    c_le = c_le;
                    c_wa = c_wa;
                    if(key_valid) begin
                        case(last_change)
                            k1: if(key_down[last_change]) custom_size = 1;
                            k2: if(key_down[last_change]) custom_size = 2;
                            k3: if(key_down[last_change]) custom_size = 3;
                            k4: if(key_down[last_change]) custom_size = 4;
                            k5: if(key_down[last_change]) custom_size = 5;
                            k6: if(key_down[last_change]) custom_size = 6;
                            k7: if(key_down[last_change]) custom_size = 7;
                            k8: if(key_down[last_change]) custom_size = 8;
                            k9: if(key_down[last_change]) custom_size = 9;
                            etr: if(key_down[last_change]) begin
                                custom_size = (custom_size == 0)? 4'b1111 : custom_size;
                                if(c_wh != 0) begin
                                    c_wh = c_wh;
                                    if(c_vo != 0) begin
                                        c_vo = c_vo;
                                        if(c_ly != 0) begin
                                            c_ly = c_ly;
                                            if(c_li != 0) begin
                                                c_li = c_li;
                                                if(c_le != 0) begin
                                                    c_le = c_le;
                                                    c_wa = custom_size;
                                                    LED = 0;
                                                    state = start;
                                                end else begin
                                                    LED = 6'b000001;
                                                    c_le = custom_size;
                                                    c_wa = 0;            
                                                end
                                            end else begin
                                                LED = 6'b000010;
                                                c_li = custom_size;
                                                c_le = 0;
                                                c_wa = 0;        
                                            end
                                        end else begin
                                            LED = 6'b000100;
                                            c_ly = custom_size;
                                            c_li = 0;
                                            c_le = 0;
                                            c_wa = 0;    
                                        end
                                    end else begin
                                        LED = 6'b001000;
                                        c_vo = custom_size;
                                        c_ly = 0;
                                        c_li = 0;
                                        c_le = 0;
                                        c_wa = 0;
                                    end
                                end else begin
                                    LED = 6'b010000;
                                    c_wh = custom_size;
                                    c_vo = 0;
                                    c_ly = 0;
                                    c_li = 0;
                                    c_le = 0;
                                    c_wa = 0;
                                end
                                custom_size = 0;
                            end
                            default: custom_size = custom_size;
                        endcase
                    end else custom_size = custom_size;
                end
                start: begin
                    state = (done == 1'b1)? order : start;
                    drink = (done == 1'b1)? 0 : drink;
                    LED = 0;
                    c_wh = (c_wh == 4'b1111)? 0 : c_wh;
                    c_vo = (c_vo == 4'b1111)? 0 : c_vo;
                    c_ly = (c_ly == 4'b1111)? 0 : c_ly;
                    c_li = (c_li == 4'b1111)? 0 : c_li;
                    c_le = (c_le == 4'b1111)? 0 : c_le;
                    c_wa = (c_wa == 4'b1111)? 0 : c_wa;
                end
            endcase
        end
    end
    
    assign bar_en = ((status == 2'b00) && (state == start))? 1'b1 : 1'b0;
    //assign _led[7] = (rst)? 1'b0 : ((bar_en)? _led[7] : ~_led[7]);
    always@(posedge clk) begin
        if(rst) dbg = 0;
        else if(bar_en) dbg = ~dbg;
        else dbg = dbg;
    end
    always@(posedge clk) begin
        if(rst) dbg2 = 0;
        else if(done) dbg2 = ~dbg2;
        else dbg2 = dbg2;
    end

    segs disp(state, clk, drink[2:0], c_wh, DISPLAY, DIGIT);

endmodule