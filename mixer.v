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