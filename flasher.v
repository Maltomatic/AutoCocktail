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