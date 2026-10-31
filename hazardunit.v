// Hazard Unit - pipeline RISC-V de 5 etapas (estilo Harris)
// - Forwarding (RAW)         : ForwardAE / ForwardBE
// - Stall (RAW con lw)       : StallF, StallD, FlushE
// - Flush (salto/jump tomado): FlushD, FlushE
module hazardunit(input  [4:0] Rs1D, Rs2D,          // etapa Decode
                  input  [4:0] Rs1E, Rs2E, RdE,     // etapa Execute
                  input  [4:0] RdM,                 // etapa Memory
                  input  [4:0] RdW,                 // etapa Writeback
                  input  [1:0] PCSrcE,              // != 00 -> salto/jump tomado
                  input        ResultSrcE0,         // 1 si la instr. en EX es lw
                  input        RegWriteM, RegWriteW,
                  output       StallF, StallD,
                  output       FlushD, FlushE,
                  output reg [1:0] ForwardAE, ForwardBE);

  wire lwStall;
  wire taken;

  // ---------------- Forwarding ----------------
  // 10 -> desde MEM (ALUResultM), 01 -> desde WB (ResultW), 00 -> sin forwarding
  always @(*) begin
    // Operando A (rs1)
    if      ((Rs1E != 5'b0) && (Rs1E == RdM) && RegWriteM) ForwardAE = 2'b10;
    else if ((Rs1E != 5'b0) && (Rs1E == RdW) && RegWriteW) ForwardAE = 2'b01;
    else                                                   ForwardAE = 2'b00;

    // Operando B (rs2)
    if      ((Rs2E != 5'b0) && (Rs2E == RdM) && RegWriteM) ForwardBE = 2'b10;
    else if ((Rs2E != 5'b0) && (Rs2E == RdW) && RegWriteW) ForwardBE = 2'b01;
    else                                                   ForwardBE = 2'b00;
  end

  // ---------------- Stall por lw (load-use) ----------------
  // lw en EX y la instruccion en ID usa su destino
  assign lwStall = ResultSrcE0 & ((Rs1D == RdE) | (Rs2D == RdE));

  assign StallF = lwStall;
  assign StallD = lwStall;

  // ---------------- Flush por control hazard ----------------
  // El salto se resuelve en EX: se descartan las 2 instrucciones siguientes
  assign FlushD = PCSrcE;
  assign FlushE = lwStall | PCSrcE;  // burbuja por lw o por salto tomado
endmodule

