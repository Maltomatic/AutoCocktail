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

module mixer(en, rst, clk, drink, c_wh, c_vo, c_ly, c_li, c_le, c_wa, stage, m_wh, m_vo, m_ly, m_li, m_le, m_wa, st, done);
    input en;
    input rst;
    input clk;
    input [2:0] drink;
    input [3:0] c_wh, c_vo, c_ly, c_li, c_le, c_wa;
    output reg [1:0] stage;
    output reg m_wh, m_vo, m_ly, m_li, m_le, m_wa, st;
    output done;

    reg [40:0] whiskey, vodka, lychee, lime, lemon, water;
    reg [30:0] timer;

    parameter custom = 3'b110, smokestack = 3'b001, vodka_lime = 3'b010,
              cheap_bliss = 3'b011, sweet_tooth = 3'b100, whiskey_sour = 3'b101;
    parameter waiting = 2'b00, order = 2'b01, pour = 2'b10, stir = 2'b11;
    parameter TPA = 40'd12000000; // 1/100 of motor time for 1 unit of alcohol

    always@(posedge clk, posedge rst) begin
        if(rst) begin            
            whiskey = 0;
            vodka = 0;
            lychee = 0;
            lime = 0;
            lemon = 0;
            water = 0;
            stage = waiting;
            timer = 100;
            st = 0;
        end else begin
            case(stage)
                waiting: begin                    
                    whiskey = 0;
                    vodka = 0;
                    lychee = 0;
                    lime = 0;
                    lemon = 0;
                    water = 0;
                    stage = waiting + en;
                    timer = 100;
                    st = 0;
                end
                order: begin                    
                    st = 0;
                    timer = 100;
                    case(drink)
                        smokestack: begin
                            whiskey = 40'd100*TPA;
                            lychee = 40'd050*TPA;
                            vodka = 0;
                            lime = 0;
                            lemon = 0;
                            water = 0;
                        end
                        vodka_lime: begin
                            vodka = 40'd050*TPA;
                            lime = 40'd010*TPA;
                            lemon = 40'd010*TPA;
                            water = 40'd033*TPA;
                            whiskey = 0;
                            lychee = 0;
                        end
                        cheap_bliss: begin
                            vodka = 40'd080*TPA;
                            lychee = 40'd020*TPA;
                            lime = 40'd040*TPA;
                            whiskey = 0;
                            lemon = 0;
                            water = 0;
                        end
                        sweet_tooth: begin
                            whiskey = 40'd100*TPA;
                            lychee = 40'd030*TPA;
                            vodka = 0;
                            lime = 0;
                            lemon = 0;
                            water = 0;
                        end
                        whiskey_sour: begin
                            whiskey = 40'd050*TPA;
                            lychee = 40'd010*TPA;
                            lime = 40'd018*TPA;
                            vodka = 0;
                            lemon = 0;
                            water = 0;
                        end
                        custom: begin
                            whiskey = c_wh*TPA*60;
                            vodka = c_vo*TPA*60;
                            lychee = c_ly*TPA*60;
                            lime = c_li*TPA*60;
                            lemon = c_le*TPA*60;
                            water = c_wa*TPA*60;
                        end
                    endcase
                    stage = pour;
                end
                pour: begin                    
                    st = 0;
                    timer = 200000000;  // prepare to stir for 2 secs
                    if(whiskey) begin
                        whiskey = whiskey-1;
                    end else whiskey = 0;
                    if(vodka) begin
                        vodka = vodka-1;
                    end else vodka = 0;
                    if(lychee) begin
                        lychee = lychee-1;
                    end else lychee = 0;
                    if(lime) begin
                        lime = lime-1;
                    end else lime = 0;
                    if(lemon) begin
                        lemon = lemon-1;
                    end else lemon = 0;
                    if(water) begin
                        water = water-1;
                    end else water = 0;
                    m_wh = (whiskey == 0)? 1'b0 : 1'b1;
                    m_vo = (vodka == 0)? 1'b0 : 1'b1;
                    m_ly = (lychee == 0)? 1'b0 : 1'b1;
                    m_li = (lime == 0)? 1'b0 : 1'b1;
                    m_le = (lemon == 0)? 1'b0 : 1'b1;
                    m_wa = (water == 0)? 1'b0 : 1'b1;
                    stage = ({m_wh, m_vo, m_ly, m_li, m_le, m_wa} == 6'b0)? stir : pour;
                end
                stir: begin
                    whiskey = 0;
                    vodka = 0;
                    lychee = 0;
                    lime = 0;
                    lemon = 0;
                    water = 0;
                    if(timer > 0) begin
                        timer = timer-1;
                        stage = stir;
                        st = 1;
                    end else begin
                        timer = 0;
                        st = 0;
                        stage = waiting;
                    end
                end
            endcase
        end
    end

    assign done = ((stage == stir) && (timer == 0))? 1'b1 : 1'b0;
endmodule

module clkdiv #(parameter n = 16) (input clk, output _clk);
    reg [n-1:0] cnt = 0;
    always@(posedge clk) cnt = cnt+1;
    assign _clk = cnt[n-1];
endmodule
    
module main_screen(
    input clk, 
    input rst,
    input [1:0] state,
    input [2:0] drink,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
    );

    wire [11:0] data;
    wire clk_2;
    clkdiv #(2) clkdiv_2(clk, clk_2);
    wire clk_25;
    clkdiv #(25) clkdiv_25(clk, clk_25);
    wire [16:0] pixel_addr_1;
    wire [14:0] pixel_addr_2;
    wire [11:0] pixel_1;
    wire [11:0] pixel_2;
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480

    //store the signal of press keyboard
    reg [2:0] kb_state;
    parameter  kb_start = 3'b000, kb_1= 3'b001, kb_2 = 3'b010, kb_3 = 3'b011, kb_4 = 3'b100, kb_5 = 3'b101, kb_6 = 3'b110;
    always @(posedge clk, posedge rst) begin
        if (rst) kb_state = kb_start;
        else begin
            case (drink)
                3'd1: kb_state = kb_1;
                3'd2: kb_state = kb_2;
                3'd3: kb_state = kb_3;
                3'd4: kb_state = kb_4;
                3'd5: kb_state = kb_5;
                3'd6: kb_state = kb_6; 
                default: kb_state = kb_start;
            endcase
        end
    end

    reg flip = 1'b0;
    always @(*) begin
        if(state == 2'b00) begin
            case(kb_state)
                kb_start: flip = 1'b0;
                kb_1: flip = ((h_cnt > 200 && h_cnt < 610) && (v_cnt > 140 && v_cnt <190))? 1'b1 : 1'b0;
                kb_2: flip = ((h_cnt > 200 && h_cnt < 610) && (v_cnt > 190 && v_cnt <240))? 1'b1 : 1'b0;
                kb_3: flip = ((h_cnt > 200 && h_cnt < 610) && (v_cnt > 240 && v_cnt <290))? 1'b1 : 1'b0;
                kb_4: flip = ((h_cnt > 200 && h_cnt < 610) && (v_cnt > 290 && v_cnt <340))? 1'b1 : 1'b0;
                kb_5: flip = ((h_cnt > 200 && h_cnt < 610) && (v_cnt > 340 && v_cnt <390))? 1'b1 : 1'b0;
                kb_6: flip = ((h_cnt > 200 && h_cnt < 610) && (v_cnt > 390 && v_cnt <440))? 1'b1 : 1'b0;
                default: flip = 1'b0;
            endcase
        end else flip = 1'b0;
    end

    reg twinkle = 1'b0;
    always @(posedge clk_25, posedge rst) begin
        if(rst) twinkle = 1'b0;
        else if(state == 2'b10) twinkle = ~twinkle;
        else twinkle = 1'b0;
    end

    //state:order, custom, start
    //assign {vgaRed, vgaGreen, vgaBlue} = (valid == 1'b1)? ((flip == 1'b1)? (255-pixel_1) : pixel_1) : 12'h0;
    assign {vgaRed, vgaGreen, vgaBlue} = (valid == 1'b1)? ((flip == 1'b1)? (255-pixel_1) :  (((h_cnt > 500 && h_cnt < 634) && (v_cnt > 0 && v_cnt <126))? ((twinkle==1'b1)? pixel_1: pixel_2) : pixel_1)) : 12'h0;

    assign pixel_addr_1 = ((h_cnt>>1)+320*(v_cnt>>1))% 76800;  //640*480 --> 320*240 
    assign pixel_addr_2 = ((h_cnt-500)+133*v_cnt)% 16758;  //640*480 --> 320*240 

     
    blk_mem_gen_0 blk_mem_gen_0_inst(
      .clka(clk_2),
      .wea(0),
      .addra(pixel_addr_1),
      .dina(data[11:0]),
      .douta(pixel_1)
    ); //background

    blk_mem_gen_1 blk_mem_gen_1_inst(
      .clka(clk_2),
      .wea(0),
      .addra(pixel_addr_2),
      .dina(data[11:0]),
      .douta(pixel_2)
    );//wine

    vga_controller   vga_inst(
      .pclk(clk_2),
      .reset(rst),
      .hsync(hsync),
      .vsync(vsync),
      .valid(valid),
      .h_cnt(h_cnt),
      .v_cnt(v_cnt)
    );
      
endmodule

module segs(state, clk, drink, size, DISPLAY, DIGIT);
    input [1:0] state;
    input clk;
    input [2:0] drink;
    input [3:0] size;
    output reg [6:0] DISPLAY = 0;
    output reg [3:0] DIGIT = 0;
    parameter order = 2'b00, customize = 2'b01, start = 2'b10;
    parameter n9 = 7'b0010000, n8 = 7'b0000000, n7 = 7'b1111000, n6 = 7'b0000010, n5 = 7'b0010010,
              n4 = 7'b0011001, n3 = 7'b0110000, n2 = 7'b0100100, n1 = 7'b1111001, n0 = 7'b1000000;

    wire d_clk;
    clkdiv #(16) fps(clk, d_clk);

    reg [1:0] idx = 0;
    reg [15:0] number = 0;
    always@(posedge d_clk) begin
        idx = idx+1;
        case(idx)
            2'b00: begin
                DIGIT = 4'b0111;
                case(drink)
                    3'd0: DISPLAY = n0;
                    3'd1: DISPLAY = n1;
                    3'd2: DISPLAY = n2;
                    3'd3: DISPLAY = n3;
                    3'd4: DISPLAY = n4;
                    3'd5: DISPLAY = n5;
                    3'd6: DISPLAY = n6;
                    default: DISPLAY = n0;
                endcase
            end
            2'b01: begin
                DIGIT = 4'b1011;
                DISPLAY = 7'b1111111;
            end
            2'b10: begin
                DIGIT = 4'b1101;
                DISPLAY = 7'b1111111;
            end
            2'b11: begin
                DIGIT = 4'b1110;
                case(size)
                    4'd0: DISPLAY = n0;
                    4'd1: DISPLAY = n1;
                    4'd2: DISPLAY = n2;
                    4'd3: DISPLAY = n3;
                    4'd4: DISPLAY = n4;
                    4'd5: DISPLAY = n5;
                    4'd6: DISPLAY = n6;
                    4'd7: DISPLAY = n7;
                    4'd8: DISPLAY = n8;
                    4'd9: DISPLAY = n9;
                    default: DISPLAY = 7'b1111111;
                endcase
            end
        endcase
    end

endmodule
