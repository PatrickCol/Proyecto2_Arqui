// E2: memoria de datos ampliada a 256 palabras (un solo puerto)
module dmem(input  clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg [31:0] RAM[255:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always @(posedge clk) begin
    if (we) RAM[a[31:2]] <= wd;
  end
endmodule
