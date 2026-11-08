`timescale 1ns/1ps
// ============================================================================
// Testbench E2 - forwarding
//   * Verifica el ORDEN DE RETIRO: el PC de cada instruccion valida que llega a WB
//     (primero la via 0 y luego la via 1) debe coincidir con la traza del programa.
//     Asi se detectan instrucciones perdidas, repetidas o ejecutadas por el camino equivocado.
//   * Verifica registros y memoria finales.
//   * Mide ciclos, IPC y uso de la doble emision, con el mismo criterio para toda arquitectura:
//     ciclos = flancos de bajada desde que baja el reset hasta que se retira la ultima
//     instruccion de la traza (el primer paso por el lazo final del programa).
//   Requiere el archivo forwarding.mem como simulation source.
// ============================================================================
module tb_forwarding;

  localparam NT = 7;      // instrucciones que deben retirarse
  localparam NM = 1;      // palabras de memoria de datos que escribe el programa

  reg         clk;
  reg         reset;
  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire        MemWrite;

  integer i;
  integer errors, retired, cycles, cycles_done, finishing;
  integer pairs, singles, stalls, flushes, ipc100, util100;
  reg [31:0] trace     [0:NT-1];
  reg [31:0] exp_reg   [0:31];
  reg [31:0] exp_maddr [0:NM-1];
  reg [31:0] exp_mval  [0:NM-1];

  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  // ---- Senales para el waveform (aparecen en el nivel superior del testbench) ----
  wire [31:0] PCF       = dut.rvpipeline.dp.PCF;
  wire [31:0] InstrF    = dut.rvpipeline.dp.InstrF;
  wire [31:0] InstrF1   = dut.rvpipeline.dp.InstrF1;
  wire [31:0] InstrD0   = dut.rvpipeline.dp.InstrD0;
  wire [31:0] InstrD1   = dut.rvpipeline.dp.InstrD1;
  wire        ValidD0   = dut.rvpipeline.dp.ValidD0;
  wire        ValidD1   = dut.rvpipeline.dp.ValidD1;
  wire        Issue0    = dut.rvpipeline.Issue0;
  wire        Issue1    = dut.rvpipeline.Issue1;
  wire [1:0]  Consumed  = dut.rvpipeline.Consumed;
  wire        RawPair   = dut.rvpipeline.RawPair;
  wire        MemConflict  = dut.rvpipeline.MemConflict;
  wire        CtrlConflict = dut.rvpipeline.CtrlConflict;
  wire        LoadUse0  = dut.rvpipeline.LoadUse0;
  wire        LoadUse1  = dut.rvpipeline.LoadUse1;
  wire        FlushD    = dut.rvpipeline.FlushD;
  wire        FlushE    = dut.rvpipeline.FlushE;
  wire        FlushM1   = dut.rvpipeline.FlushM1;
  wire [2:0]  ForwardA0 = dut.rvpipeline.ForwardA0;
  wire [2:0]  ForwardB0 = dut.rvpipeline.ForwardB0;
  wire [2:0]  ForwardA1 = dut.rvpipeline.ForwardA1;
  wire [2:0]  ForwardB1 = dut.rvpipeline.ForwardB1;
  wire [31:0] InstrE0   = dut.rvpipeline.dp.InstrE0;
  wire [31:0] InstrE1   = dut.rvpipeline.dp.InstrE1;
  wire [31:0] InstrM0   = dut.rvpipeline.dp.InstrM0;
  wire [31:0] InstrM1   = dut.rvpipeline.dp.InstrM1;
  wire [31:0] InstrW0   = dut.rvpipeline.dp.InstrW0;
  wire [31:0] InstrW1   = dut.rvpipeline.dp.InstrW1;
  wire        ValidW0   = dut.rvpipeline.dp.ValidW0;
  wire        ValidW1   = dut.rvpipeline.dp.ValidW1;
  wire [31:0] PCW0      = dut.rvpipeline.dp.PCW0;
  wire [31:0] PCW1      = dut.rvpipeline.dp.PCW1;

  // ---- Valores esperados (generados con el simulador de referencia) ----
  initial begin
    errors = 0; retired = 0; cycles = 0; cycles_done = 0; finishing = 0;
    pairs = 0; singles = 0; stalls = 0; flushes = 0;
    trace[0] = 32'h00000000;
    trace[1] = 32'h00000004;
    trace[2] = 32'h00000008;
    trace[3] = 32'h0000000c;
    trace[4] = 32'h00000010;
    trace[5] = 32'h00000014;
    trace[6] = 32'h00000018;
    exp_reg[0] = 32'd0;
    exp_reg[1] = 32'd5;
    exp_reg[2] = 32'd10;
    exp_reg[3] = 32'd15;
    exp_reg[4] = 32'd10;
    exp_reg[5] = 32'd25;
    exp_reg[6] = 32'd35;
    exp_reg[7] = 32'd0;
    exp_reg[8] = 32'd0;
    exp_reg[9] = 32'd0;
    exp_reg[10] = 32'd0;
    exp_reg[11] = 32'd0;
    exp_reg[12] = 32'd0;
    exp_reg[13] = 32'd0;
    exp_reg[14] = 32'd0;
    exp_reg[15] = 32'd0;
    exp_reg[16] = 32'd0;
    exp_reg[17] = 32'd0;
    exp_reg[18] = 32'd0;
    exp_reg[19] = 32'd0;
    exp_reg[20] = 32'd0;
    exp_reg[21] = 32'd0;
    exp_reg[22] = 32'd0;
    exp_reg[23] = 32'd0;
    exp_reg[24] = 32'd0;
    exp_reg[25] = 32'd0;
    exp_reg[26] = 32'd0;
    exp_reg[27] = 32'd0;
    exp_reg[28] = 32'd0;
    exp_reg[29] = 32'd0;
    exp_reg[30] = 32'd0;
    exp_reg[31] = 32'd0;
    exp_maddr[0] = 32'd0; exp_mval[0] = 32'd0;
  end

  // ---- Reloj de 10 ns y reset de 22 ns ----
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 1;
    #1;
    for (i = 0; i < 256; i = i + 1) dut.imem.RAM[i] = 32'h00000013;   // memoria sin programar = NOP
    for (i = 0; i < 256; i = i + 1) dut.dmem.RAM[i] = 32'h00000000;
    $readmemh("forwarding.mem", dut.imem.RAM);
    #21;
    reset = 0;
  end

  // ---- Monitor: se evalua en cada flanco de bajada ----
  always @(negedge clk) begin
    if (reset === 1'b0 && finishing < 2) begin
      cycles = cycles + 1;

      // Estadisticas de emision (par en Decode)
      if (Issue1 === 1'b1)        pairs   = pairs + 1;
      else if (Issue0 === 1'b1)   singles = singles + 1;
      else if (ValidD0 === 1'b1)  stalls  = stalls + 1;
      if (FlushD === 1'b1)        flushes = flushes + 1;

      if (finishing == 0) begin
        // Retiro en orden de programa: primero la via 0 y luego la via 1
        if (ValidW0 === 1'b1) begin
          if (retired < NT) begin
            if (PCW0 !== trace[retired]) begin
              $display("ERROR: retiro #%0d: PC=%h (esperado %h)", retired, PCW0, trace[retired]);
              errors = errors + 1;
            end
          end
          retired = retired + 1;
        end
        if (ValidW1 === 1'b1) begin
          if (retired < NT) begin
            if (PCW1 !== trace[retired]) begin
              $display("ERROR: retiro #%0d: PC=%h (esperado %h)", retired, PCW1, trace[retired]);
              errors = errors + 1;
            end
          end
          retired = retired + 1;
        end
        if (retired >= NT) begin
          finishing = 1;
          cycles_done = cycles;
        end
      end else begin
        // Un ciclo despues del ultimo retiro: el Register File ya escribio todo
        finishing = 2;
        if (retired != NT) begin
          $display("ERROR: se retiraron %0d instrucciones (esperado %0d)", retired, NT);
          errors = errors + 1;
        end
        for (i = 1; i < 32; i = i + 1)
          if (dut.rvpipeline.dp.rf.rf[i] !== exp_reg[i]) begin
            $display("ERROR: x%0d = %0d (esperado %0d)", i, dut.rvpipeline.dp.rf.rf[i], exp_reg[i]);
            errors = errors + 1;
          end
        for (i = 0; i < NM; i = i + 1)
          if (dut.dmem.RAM[exp_maddr[i]] !== exp_mval[i]) begin
            $display("ERROR: mem[%0d] = %0d (esperado %0d)", exp_maddr[i], dut.dmem.RAM[exp_maddr[i]], exp_mval[i]);
            errors = errors + 1;
          end

        ipc100  = (retired * 100) / cycles_done;
        util100 = (pairs * 100) / (pairs + singles + stalls + 1);
        $display("=======================================================");
        $display(" Programa            : forwarding");
        $display(" Instrucciones       : %0d", retired);
        $display(" Ciclos              : %0d", cycles_done);
        $display(" IPC                 : %0d.%02d", ipc100 / 100, ipc100 % 100);
        $display(" Pares emitidos      : %0d   Individuales: %0d   Stalls: %0d   Flushes: %0d", pairs, singles, stalls, flushes);
        if (errors == 0)
          $display(" PASS: el programa se ejecuto correctamente");
        else
          $display(" FAIL: %0d error(es)", errors);
        $display("=======================================================");
        $finish;
      end
    end
  end

  // ---- Guarda de timeout ----
  initial begin
    #200000;
    $display("TIMEOUT: se retiraron %0d de %0d instrucciones. Revisa el .mem y los nombres de instancia.", retired, NT);
    $finish;
  end

endmodule
