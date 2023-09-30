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