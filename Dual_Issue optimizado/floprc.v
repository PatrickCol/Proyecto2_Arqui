// Registro con reset asincrono y clear sincrono (flush)
module floprc #(parameter WIDTH = 8)
               (input                  clk, reset, clear,
                input      [WIDTH-1:0] d,
                output reg [WIDTH-1:0] q);
  always @(posedge clk, posedge reset)
    if (reset)      q <= 0;
    else if (clear) q <= 0;
    else            q <= d;
endmodule
