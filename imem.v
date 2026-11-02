// Dual Fetch: rd = instruccion en a, rd1 = instruccion en a+4
module imem(input  [31:0] a,
            output [31:0] rd, rd1);
  
  reg [31:0] RAM[63:0]; 

  initial begin
      $readmemh("riscvtest.dat",RAM); 
  end

  assign rd  = RAM[a[31:2]];     // word aligned
  assign rd1 = RAM[a[31:2] + 1];
endmodule
