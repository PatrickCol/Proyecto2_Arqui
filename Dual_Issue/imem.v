// Dual Fetch: rd = instruccion en a, rd1 = instruccion en a+4
// E2: memoria ampliada a 256 palabras; la memoria sin programar es NOP
module imem(input  [31:0] a,
            output [31:0] rd, rd1);

  reg [31:0] RAM[255:0];
  integer i;

  initial begin
      for (i = 0; i < 256; i = i + 1) RAM[i] = 32'h00000013;  // addi x0, x0, 0
      $readmemh("riscvtest.dat", RAM);
  end

  assign rd  = RAM[a[31:2]];     // word aligned
  assign rd1 = RAM[a[31:2] + 1];
endmodule
