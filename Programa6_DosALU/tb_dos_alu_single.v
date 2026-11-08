`timescale 1ns/1ps
// ============================================================================
// Testbench E2 - dos_alu (arquitectura A: pipeline Single-Issue)
//   Mismo criterio que el testbench Dual-Issue, para que la comparacion sea justa:
//     * retiro = instruccion valida que llega a WB; su PC es PCPlus4W - 4.
//       Una burbuja o un NOP de flush tiene PCPlus4W = 0, por eso no se cuenta.
//     * ciclos = flancos de bajada desde que baja el reset hasta que se retira la ultima
//       instruccion de la traza (el primer paso por el lazo final del programa).
//   Requiere dos_alu.mem como simulation source.
// ============================================================================
module tb_dos_alu_single;

  localparam NT = 17;
  localparam NM = 1;

  reg         clk;
  reg         reset;
  wire [31:0] WriteData;
  wire [31:0] DataAdr;
  wire        MemWrite;

  integer i;
  integer errors, retired, cycles, cycles_done, finishing;
  integer stalls, flushes, ipc100;
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

  // ---- Senales para el waveform ----
  wire [31:0] PCF       = dut.rvpipeline.dp.PCF;
  wire [31:0] InstrD    = dut.rvpipeline.dp.InstrD;
  wire        StallF    = dut.rvpipeline.dp.StallF;
  wire        StallD    = dut.rvpipeline.dp.StallD;
  wire        FlushD    = dut.rvpipeline.dp.FlushD;
  wire        FlushE    = dut.rvpipeline.dp.FlushE;
  wire [1:0]  ForwardAE = dut.rvpipeline.dp.ForwardAE;
  wire [1:0]  ForwardBE = dut.rvpipeline.dp.ForwardBE;
  wire [31:0] PCPlus4W  = dut.rvpipeline.dp.PCPlus4W;

  initial begin
    errors = 0; retired = 0; cycles = 0; cycles_done = 0; finishing = 0;
    stalls = 0; flushes = 0;
    trace[0] = 32'h00000000;
    trace[1] = 32'h00000004;
    trace[2] = 32'h00000008;
    trace[3] = 32'h0000000c;
    trace[4] = 32'h00000010;
    trace[5] = 32'h00000014;
    trace[6] = 32'h00000018;
    trace[7] = 32'h0000001c;
    trace[8] = 32'h00000020;
    trace[9] = 32'h00000024;
    trace[10] = 32'h00000028;
    trace[11] = 32'h0000002c;
    trace[12] = 32'h00000030;
    trace[13] = 32'h00000034;
    trace[14] = 32'h00000038;
    trace[15] = 32'h0000003c;
    trace[16] = 32'h00000040;
    exp_reg[0] = 32'd0;
    exp_reg[1] = 32'd1;
    exp_reg[2] = 32'd2;
    exp_reg[3] = 32'd3;
    exp_reg[4] = 32'd4;
    exp_reg[5] = 32'd5;
    exp_reg[6] = 32'd6;
    exp_reg[7] = 32'd7;
    exp_reg[8] = 32'd8;
    exp_reg[9] = 32'd3;
    exp_reg[10] = 32'd4294967295;
    exp_reg[11] = 32'd4;
    exp_reg[12] = 32'd15;
    exp_reg[13] = 32'd2;
    exp_reg[14] = 32'd1;
    exp_reg[15] = 32'd15;
    exp_reg[16] = 32'd26;
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

  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  initial begin
    reset = 1;
    #1;
    for (i = 0; i < 64; i = i + 1) dut.imem.RAM[i] = 32'h00000013;
    for (i = 0; i < 64; i = i + 1) dut.dmem.RAM[i] = 32'h00000000;
    $readmemh("dos_alu.mem", dut.imem.RAM);
    #21;
    reset = 0;
  end

  always @(negedge clk) begin
    if (reset === 1'b0 && finishing < 2) begin
      cycles = cycles + 1;
      if (StallF === 1'b1) stalls  = stalls + 1;
      if (FlushD === 1'b1) flushes = flushes + 1;

      if (finishing == 0) begin
        if (PCPlus4W !== 32'd0) begin
          if (retired < NT) begin
            if ((PCPlus4W - 4) !== trace[retired]) begin
              $display("ERROR: retiro #%0d: PC=%h (esperado %h)", retired, PCPlus4W - 4, trace[retired]);
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

        ipc100 = (retired * 100) / cycles_done;
        $display("=======================================================");
        $display(" Programa            : dos_alu (Single-Issue)");
        $display(" Instrucciones       : %0d", retired);
        $display(" Ciclos              : %0d", cycles_done);
        $display(" IPC                 : %0d.%02d", ipc100 / 100, ipc100 % 100);
        $display(" Stalls: %0d   Flushes: %0d", stalls, flushes);
        if (errors == 0)
          $display(" PASS: el programa se ejecuto correctamente");
        else
          $display(" FAIL: %0d error(es)", errors);
        $display("=======================================================");
        $finish;
      end
    end
  end

  initial begin
    #200000;
    $display("TIMEOUT: se retiraron %0d de %0d instrucciones.", retired, NT);
    $finish;
  end

endmodule
