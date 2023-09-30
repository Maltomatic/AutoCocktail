module debounce(pb_debounced, pb, clk);
  output pb_debounced;
  input clk;
  input pb;

  reg [3:0] filter = 0;
  always@(posedge clk) filter[3:0] <= {filter[2:0], pb};

  assign pb_debounced = (filter == 4'b1111);
endmodule