module div(input clk, output _clk);
    reg [11:0] cnt = 0;
    always@(posedge clk) cnt <= cnt+1;
    assign _clk = cnt[11];
endmodule

module motors(input dn, input clk, input rst, output reg in1, output enA, output led);   
    wire clkdv;
    div cld(clk, clkdv);
    wire ddn, _dn;
    debounce boing(ddn, dn, clkdv);
    one_pulse op(ddn, clk, _dn);

    always@(posedge clk) begin
        if(rst) in1 = 0;
        else begin
            if(_dn) in1 = !in1;
            else in1 = in1;
        end
    end

    assign led = in1;
    assign enA = clk;

endmodule