module div(input clk, output _clk);
    reg [11:0] cnt = 0;
    always@(posedge clk) cnt <= cnt+1;
    assign _clk = cnt[11];
endmodule

module test(input clk, input rst, input dn, output reg light, output led);
    wire press;
    div btn(clk, press);
    wire ddn, _dn;
    debounce boing(ddn, dn, press);
    one_pulse(ddn, clk, _dn);

    always@(posedge clk) begin
        if(rst) light = 1;
        else begin
            if(_dn) light = !light;
            else light = light;
        end
    end

    assign led = light;

endmodule