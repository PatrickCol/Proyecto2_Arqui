// Top con memoria de datos de doble puerto. Se mantienen los 5 puertos de E1/E2 para no
// romper los testbenches: MemWrite = MemWrite0 | MemWrite1; DataAdr/WriteData salen de la via 1
// si esta escribe, si no de la via 0. Para ver ambos puertos usa dut.MemWrite0/1, dut.DataAdr0/1...
module top(input  clk, reset,
           output [31:0] WriteData, DataAdr,
           output MemWrite);

  wire [31:0] PC, Instr, Instr1;
  wire [31:0] ReadData0, ReadData1, DataAdr0, DataAdr1, WriteData0, WriteData1;
  wire        MemWrite0, MemWrite1;

  assign MemWrite  = MemWrite0 | MemWrite1;
  assign DataAdr   = MemWrite1 ? DataAdr1   : DataAdr0;
  assign WriteData = MemWrite1 ? WriteData1 : WriteData0;

  riscvpipeline rvpipeline(
    .clk(clk), .reset(reset), .PC(PC), .Instr(Instr), .Instr1(Instr1),
    .MemWrite0(MemWrite0), .MemWrite1(MemWrite1),
    .ALUResult0(DataAdr0), .ALUResult1(DataAdr1),
    .WriteData0(WriteData0), .WriteData1(WriteData1),
    .ReadData0(ReadData0), .ReadData1(ReadData1)
  );

  imem imem(.a(PC), .rd(Instr), .rd1(Instr1));

  dmem dmem(
    .clk(clk), .we0(MemWrite0), .we1(MemWrite1),
    .a0(DataAdr0), .a1(DataAdr1), .wd0(WriteData0), .wd1(WriteData1),
    .rd0(ReadData0), .rd1(ReadData1)
  );
endmodule