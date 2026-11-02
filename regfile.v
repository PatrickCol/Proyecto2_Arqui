// Register File Dual-Issue: 4 lecturas y 2 escrituras por ciclo
//   Via 0: lee a1, a2 y escribe a3
//   Via 1: lee b1, b2 y escribe b3
// Si ambas vias escriben el mismo registro, gana la via 1 (instruccion mas joven)
module regfile (input  clk, 
               input  we3, 
               input  [ 4:0] a1, a2, a3, 
               input  [31:0] wd3, 
               output [31:0] rd1, rd2,
               input         web3,
               input  [ 4:0] b1, b2, b3,
               input  [31:0] wdb3,
               output [31:0] rdb1, rdb2); 

  reg [31:0] rf[31:0]; 

  integer i;
  initial for (i = 0; i < 32; i = i + 1) rf[i] = 0;

  // CHANGE 2A: escribir en flanco de BAJADA (escribe 1a mitad, lee 2a mitad)
  always @(negedge clk) begin
    if (we3)  rf[a3] <= wd3;
    if (web3) rf[b3] <= wdb3;   // va despues: tiene prioridad
  end

  assign rd1  = (a1 != 0) ? rf[a1] : 0;
  assign rd2  = (a2 != 0) ? rf[a2] : 0;
  assign rdb1 = (b1 != 0) ? rf[b1] : 0;
  assign rdb2 = (b2 != 0) ? rf[b2] : 0;
endmodule
