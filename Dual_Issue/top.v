module top(input  clk, reset, 
           output [31:0] WriteData, DataAdr, 
           output MemWrite);
  
  wire [31:0] PC, Instr, Instr1, ReadData; 
  
  // instantiate processor and memories
  riscvpipeline rvpipeline(
    .clk(clk), 
    .reset(reset), 
    .PC(PC), 
    .Instr(Instr), 
    .Instr1(Instr1), 
    .MemWrite(MemWrite), 
    .ALUResult(DataAdr), 
    .WriteData(WriteData), 
    .ReadData(ReadData)
  ); 

  imem imem(
    .a(PC), 
    .rd(Instr),
    .rd1(Instr1)
  ); 

  dmem dmem(
    .clk(clk), 
    .we(MemWrite), 
    .a(DataAdr), 
    .wd(WriteData), 
    .rd(ReadData)
  ); 
endmodule