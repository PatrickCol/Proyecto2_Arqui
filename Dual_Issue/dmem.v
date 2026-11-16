// Memoria de datos de UN puerto (arquitectura B, Dual-Issue de E2), ampliada a 512 palabras
// para el programa del profesor (x1 = 1536). Es la dmem de E2 con RAM[511:0].
module dmem(input  clk, we,
            input  [31:0] a, wd,
            output [31:0] rd);

  reg [31:0] RAM[511:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always @(posedge clk) begin
    if (we) RAM[a[31:2]] <= wd;
  end
endmodule