`timescale 1ns/1ps
// ============================================================
//  testbench: solo lo esencial (clk, reset y las salidas de top).
//  Toda la verificacion vive en tb_checker, para que sus variables
//  internas NO aparezcan en el waveform por defecto.
// ============================================================
module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;

  top dut(
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

  // ---- Senales del pipeline para el waveform (referencias jerarquicas) ----
  // Declaradas aqui, aparecen por defecto junto a clk, reset, MemWrite...
  wire [31:0] PCF     = dut.rvpipeline.dp.PCF;
  wire [31:0] InstrF  = dut.rvpipeline.dp.InstrF;
  wire [31:0] InstrD  = dut.rvpipeline.dp.InstrD;
  wire [31:0] InstrE  = dut.rvpipeline.dp.InstrE;
  wire [31:0] InstrM  = dut.rvpipeline.dp.InstrM;
  wire [31:0] InstrW  = dut.rvpipeline.dp.InstrW;
  // Opcionales, utiles para explicar burbujas y adelantamientos
  wire [31:0] ResultW = dut.rvpipeline.dp.ResultW;
  wire        StallF  = dut.rvpipeline.dp.StallF;
  wire        FlushD  = dut.rvpipeline.dp.FlushD;
  wire        FlushE  = dut.rvpipeline.dp.FlushE;
  wire [1:0]  ForwardAE = dut.rvpipeline.dp.ForwardAE;
  wire [1:0]  ForwardBE = dut.rvpipeline.dp.ForwardBE;

  initial begin
    reset = 1; #22; reset = 0;
  end

  always begin
    clk = 1; #5; clk = 0; #5;   // periodo de 10 ns
  end

  // PROGRAM: 1 = sin dependencias, 2 = forwarding/stalling/flushing
  // VERBOSE: 1 = imprime una linea por ciclo en la consola
  tb_checker #(.PROGRAM(2), .VERBOSE(0)) chk(
    .clk(clk),
    .reset(reset),
    .MemWrite(MemWrite),
    .DataAdr(DataAdr),
    .WriteData(WriteData)
  );
endmodule


// ============================================================
//  tb_checker: self-check (stores, registros, stalls) + timeout
// ============================================================
module tb_checker #(parameter PROGRAM = 2, parameter VERBOSE = 0)
                   (input        clk, reset, MemWrite,
                    input [31:0] DataAdr, WriteData);

  integer     N_EXP, EXP_STALLS;
  reg [31:0]  exp_addr [0:7];
  reg [31:0]  exp_data [0:7];
  reg [31:0]  exp_reg  [0:31];
  reg         chk_reg  [0:31];

  integer k;
  initial begin
    for (k = 0; k < 32; k = k + 1) begin
      exp_reg[k] = 0;
      chk_reg[k] = 0;
    end

    if (PROGRAM == 1) begin
      N_EXP = 3;  EXP_STALLS = 0;
      exp_addr[0] = 0;  exp_data[0] = 1;
      exp_addr[1] = 4;  exp_data[1] = 2;
      exp_addr[2] = 8;  exp_data[2] = 3;
      for (k = 1; k <= 12; k = k + 1) begin
        exp_reg[k] = k;  chk_reg[k] = 1;
      end
    end else begin
      N_EXP = 2;  EXP_STALLS = 1;
      exp_addr[0] = 0;  exp_data[0] = 10;
      exp_addr[1] = 4;  exp_data[1] = 15;
      exp_reg[1]  = 5;   chk_reg[1]  = 1;
      exp_reg[2]  = 10;  chk_reg[2]  = 1;
      exp_reg[3]  = 15;  chk_reg[3]  = 1;
      exp_reg[4]  = 10;  chk_reg[4]  = 1;
      exp_reg[5]  = 10;  chk_reg[5]  = 1;
      exp_reg[6]  = 10;  chk_reg[6]  = 1;
      exp_reg[7]  = 15;  chk_reg[7]  = 1;
      exp_reg[8]  = 0;   chk_reg[8]  = 1;   // descartado por el flush
      exp_reg[9]  = 0;   chk_reg[9]  = 1;   // descartado por el flush
      exp_reg[10] = 1;   chk_reg[10] = 1;
      exp_reg[11] = 2;   chk_reg[11] = 1;
    end
  end

  integer stall_cycles = 0;
  integer flush_cycles = 0;
  integer n_stores     = 0;
  integer errors       = 0;
  integer r;

  // Conteo de stalls/flushes (y monitor opcional)
  always @(negedge clk) if (reset === 1'b0) begin
    if (testbench.dut.rvpipeline.dp.StallF === 1'b1) stall_cycles = stall_cycles + 1;
    if (testbench.dut.rvpipeline.dp.FlushD === 1'b1) flush_cycles = flush_cycles + 1;
    if (VERBOSE)
      $display("%8t | PCF=%h InstrD=%h | Stall=%b FlushD=%b FlushE=%b | FwdA=%b FwdB=%b",
               $time,
               testbench.dut.rvpipeline.dp.PCF,
               testbench.dut.rvpipeline.dp.InstrD,
               testbench.dut.rvpipeline.dp.StallF,
               testbench.dut.rvpipeline.dp.FlushD,
               testbench.dut.rvpipeline.dp.FlushE,
               testbench.dut.rvpipeline.dp.ForwardAE,
               testbench.dut.rvpipeline.dp.ForwardBE);
  end

  // Verificacion de cada STORE y, al final, de registros y stalls
  always @(negedge clk) begin
    if (reset === 1'b0 && MemWrite === 1'b1) begin
      $display("[%0t] STORE  mem[%0d] <= %0d", $time, DataAdr, WriteData);

      if (n_stores < N_EXP) begin
        if (DataAdr === exp_addr[n_stores] && WriteData === exp_data[n_stores])
          n_stores = n_stores + 1;
        else begin
          $display("\n=======================================================");
          $display("  SIMULATION FAILED! Store #%0d incorrecto.", n_stores);
          $display("  Esperado: mem[%0d] <= %0d", exp_addr[n_stores], exp_data[n_stores]);
          $display("  Obtenido: mem[%0d] <= %0d", DataAdr, WriteData);
          $display("=======================================================\n");
          $finish;
        end
      end

      if (n_stores == N_EXP) begin
        #1;
        for (r = 0; r < 32; r = r + 1)
          if (chk_reg[r] && testbench.dut.rvpipeline.dp.rf.rf[r] !== exp_reg[r]) begin
            $display("  ERROR: x%0d = %0d (esperado %0d)",
                     r, testbench.dut.rvpipeline.dp.rf.rf[r], exp_reg[r]);
            errors = errors + 1;
          end
        if (stall_cycles !== EXP_STALLS) begin
          $display("  ERROR: ciclos de stall = %0d (esperado %0d)", stall_cycles, EXP_STALLS);
          errors = errors + 1;
        end

        $display("\n=======================================================");
        if (errors == 0)
          $display("  SIMULATION SUCCEEDED! Programa %0d ejecutado correctamente.", PROGRAM);
        else
          $display("  SIMULATION FAILED! %0d error(es).", errors);
        $display("  Ciclos con stall: %0d | Ciclos con flush (FlushD): %0d", stall_cycles, flush_cycles);
        $display("=======================================================\n");
        $finish;
      end
    end
  end

  // Timeout
  initial begin
    #2000;
    $display("\nTIMEOUT: se completaron %0d de %0d stores. Revisa el .dat y los nombres de instancia.",
             n_stores, N_EXP);
    $finish;
  end
endmodule