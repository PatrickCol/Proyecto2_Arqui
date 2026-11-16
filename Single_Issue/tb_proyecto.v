// =====================================================================================
// Testbench del programa de pruebas del profesor (etapas A-D) - Dual-Issue y Optimizado.
//  * Comprueba el estado arquitectonico (registros + memoria) en el instante en que la ULTIMA
//    instruccion util de cada etapa se retira en WB. Los registros se comprueban contra un banco
//    "sombra" que se actualiza solo con lo que se retira, en orden de programa, asi una instruccion
//    de la etapa siguiente que se retire en el mismo ciclo no falsea la comprobacion.
//  * Mide ciclos e instrucciones retiradas SIN el bucle fin (se detiene al retirar el ultimo sw de D).
//  * Cuenta causas de emision (doble emision, RAW, load-use, conflicto de memoria, control, flush).
// Uso: copiar riscvtest.dat (generado del programa) a la carpeta de simulacion; ampliar dmem a 512 palabras.
// Senales para waveforms: etapa_cerrada[3:0], etapa_ok[3:0], etapa_pulso[3:0], M_* (memoria), sx* (registros).
// Para el pipeline single-issue (A): define SINGLE y ajusta el bloque de macros de abajo.
// =====================================================================================
`timescale 1ns/1ps
`define SINGLE   // carpeta Single_Issue: arquitectura A
module tb_proyecto;
  localparam [31:0] PC_A = 32'h34, PC_B = 32'h60, PC_C = 32'hE0, PC_D = 32'h160; // PC del ultimo sw de cada etapa
  localparam integer RET_A = 14, RET_B = 25, RET_C = 241, RET_D = 312;           // retiradas esperadas (emulador ISA)
  localparam integer BASE_IDX = 384;       // x1 = 1536 -> palabra 384
  localparam integer MAX_CYC  = 5000;

  reg clk, reset;
  wire [31:0] WriteData, DataAdr;
  wire MemWrite;
  top dut(.clk(clk), .reset(reset), .WriteData(WriteData), .DataAdr(DataAdr), .MemWrite(MemWrite));

  // ---- nombres jerarquicos del retiro (WB) y de la emision: AJUSTAR si cambian en tu implementacion ----
`ifndef SINGLE
  `define V0   dut.rvpipeline.ValidW0
  `define V1   dut.rvpipeline.ValidW1
  `define PC0  dut.rvpipeline.PCW0
  `define PC1  dut.rvpipeline.PCW1
  `define RW0  dut.rvpipeline.RegWriteW0
  `define RW1  dut.rvpipeline.RegWriteW1
  `define RD0  dut.rvpipeline.RdW0
  `define RD1  dut.rvpipeline.RdW1
  `define RES0 dut.rvpipeline.dp.ResultW0
  `define RES1 dut.rvpipeline.dp.ResultW1
`else
  // Pipeline single-issue: una sola via. Pon aqui TUS senales de WB (valida, PC, RegWrite, Rd, ResultW).
  // Retiro = instruccion valida en WB: burbujas/flush tienen PCPlus4W = 0 (mismo criterio que los TB de E2)
  `define V0   (dut.rvpipeline.dp.PCPlus4W != 32'd0)
  `define PC0  (dut.rvpipeline.dp.PCPlus4W - 32'd4)
  `define RW0  dut.rvpipeline.RegWriteW
  `define RD0  dut.rvpipeline.RdW
  `define RES0 dut.rvpipeline.dp.ResultW
  `define V1   1'b0
  `define PC1  32'hFFFFFFFF
  `define RW1  1'b0
  `define RD1  5'd0
  `define RES1 32'd0
`endif

  // ---- reloj y reset ----
  always begin clk = 1; #5 clk = 0; #5; end
  initial begin reset = 1; repeat (2) @(posedge clk); #1 reset = 0; end

  // ---- valores esperados (del PDF del profesor) ----
  reg [31:0] eR [0:127];    // eR[etapa*32 + registro]
  reg [31:0] eM [0:63];     // eM[etapa*16 + offset/4]
  reg        eMk[0:63];     // 1 si esa palabra se comprueba
  integer i0;
  initial begin
    for (i0 = 0; i0 < 128; i0 = i0 + 1) eR[i0]  = 0;
    for (i0 = 0; i0 < 64;  i0 = i0 + 1) begin eM[i0] = 0; eMk[i0] = 0; end
    eR[1] = 1536;
    eR[2] = 1;
    eR[3] = 8;
    eR[4] = 3;
    eR[5] = 11;
    eR[6] = 5;
    eR[7] = 16;
    eR[8] = 2;
    eR[9] = 7;
    eR[10] = 12;
    eM[0] = 11; eMk[0] = 1;
    eM[1] = 5; eMk[1] = 1;
    eM[2] = 12; eMk[2] = 1;
    eR[33] = 1536;
    eR[34] = 1;
    eR[35] = 8;
    eR[36] = 3;
    eR[37] = 11;
    eR[38] = 5;
    eR[39] = 16;
    eR[40] = 2;
    eR[41] = 7;
    eR[42] = 12;
    eR[43] = 11;
    eR[44] = 16;
    eR[45] = 5;
    eR[46] = 12;
    eR[47] = 7;
    eR[48] = 7;
    eR[49] = 16;
    eR[50] = 23;
    eM[16] = 11; eMk[16] = 1;
    eM[17] = 5; eMk[17] = 1;
    eM[18] = 12; eMk[18] = 1;
    eM[19] = 7; eMk[19] = 1;
    eM[20] = 16; eMk[20] = 1;
    eM[21] = 23; eMk[21] = 1;
    eR[65] = 1536;
    eR[66] = 1;
    eR[67] = 8;
    eR[68] = 3;
    eR[69] = 11;
    eR[70] = 5;
    eR[71] = 16;
    eR[72] = 2;
    eR[73] = 7;
    eR[74] = 12;
    eR[75] = 11;
    eR[76] = 16;
    eR[77] = 5;
    eR[78] = 12;
    eR[79] = 7;
    eR[80] = 7;
    eR[81] = 16;
    eR[82] = 23;
    eR[83] = 12;
    eR[84] = 12;
    eR[85] = 24;
    eR[86] = 18;
    eR[88] = 24;
    eR[90] = 6;
    eM[32] = 11; eMk[32] = 1;
    eM[33] = 5; eMk[33] = 1;
    eM[34] = 12; eMk[34] = 1;
    eM[35] = 7; eMk[35] = 1;
    eM[36] = 16; eMk[36] = 1;
    eM[37] = 23; eMk[37] = 1;
    eM[38] = 24; eMk[38] = 1;
    eM[39] = 18; eMk[39] = 1;
    eM[40] = 24; eMk[40] = 1;
    eR[97] = 1536;
    eR[98] = 1;
    eR[99] = 8;
    eR[100] = 3;
    eR[101] = 11;
    eR[102] = 5;
    eR[103] = 16;
    eR[104] = 2;
    eR[105] = 7;
    eR[106] = 12;
    eR[107] = 11;
    eR[108] = 16;
    eR[109] = 5;
    eR[110] = 12;
    eR[111] = 7;
    eR[112] = 7;
    eR[113] = 16;
    eR[114] = 23;
    eR[115] = 6;
    eR[116] = 6;
    eR[117] = 24;
    eR[118] = 18;
    eR[120] = 24;
    eR[121] = 4;
    eR[122] = 4;
    eR[123] = 1560;
    eR[124] = 74;
    eR[125] = 4;
    eR[126] = 23;
    eR[127] = 1;
    eM[48] = 11; eMk[48] = 1;
    eM[49] = 5; eMk[49] = 1;
    eM[50] = 12; eMk[50] = 1;
    eM[51] = 7; eMk[51] = 1;
    eM[52] = 16; eMk[52] = 1;
    eM[53] = 23; eMk[53] = 1;
    eM[54] = 24; eMk[54] = 1;
    eM[55] = 18; eMk[55] = 1;
    eM[56] = 24; eMk[56] = 1;
    eM[57] = 74; eMk[57] = 1;
    eM[58] = 4; eMk[58] = 1;
    eM[59] = 0; eMk[59] = 1;
    eM[60] = 1; eMk[60] = 1;
    eM[61] = 1; eMk[61] = 1;
  end

  // ---- estado de la medicion ----
  reg [31:0] sh [0:31];                 // banco de registros "sombra" (solo lo retirado)
  integer cyc, retired, k, errs_total;
  reg done;
  reg [3:0] etapa_cerrada, etapa_ok, etapa_pulso;
  integer c_dual, c_single, c_stall_lu0, c_bubble, c_raw, c_ctrl, c_lu1, c_memblk, c_mem2, c_mem2pair, c_flush;
  integer cyc_A, cyc_B, cyc_C, cyc_D;
  initial begin
    cyc = 0; retired = 0; errs_total = 0; done = 0;
    etapa_cerrada = 0; etapa_ok = 0; etapa_pulso = 0;
    c_dual = 0; c_single = 0; c_stall_lu0 = 0; c_bubble = 0; c_raw = 0; c_ctrl = 0; c_lu1 = 0;
    c_memblk = 0; c_mem2 = 0; c_mem2pair = 0; c_flush = 0;
    for (k = 0; k < 32; k = k + 1) sh[k] = 0;
  end

  // ---- senales utiles para waveforms ----
  wire [31:0] M_00 = dut.dmem.RAM[BASE_IDX+0],  M_04 = dut.dmem.RAM[BASE_IDX+1],  M_08 = dut.dmem.RAM[BASE_IDX+2];
  wire [31:0] M_12 = dut.dmem.RAM[BASE_IDX+3],  M_16 = dut.dmem.RAM[BASE_IDX+4],  M_20 = dut.dmem.RAM[BASE_IDX+5];
  wire [31:0] M_24 = dut.dmem.RAM[BASE_IDX+6],  M_28 = dut.dmem.RAM[BASE_IDX+7],  M_32 = dut.dmem.RAM[BASE_IDX+8];
  wire [31:0] M_36 = dut.dmem.RAM[BASE_IDX+9],  M_40 = dut.dmem.RAM[BASE_IDX+10], M_44 = dut.dmem.RAM[BASE_IDX+11];
  wire [31:0] M_48 = dut.dmem.RAM[BASE_IDX+12], M_52 = dut.dmem.RAM[BASE_IDX+13];
  wire [31:0] sx5 = sh[5], sx6 = sh[6], sx10 = sh[10], sx18 = sh[18], sx21 = sh[21], sx22 = sh[22],
              sx24 = sh[24], sx28 = sh[28], sx29 = sh[29], sx31 = sh[31];

  // ---- comprobacion de una etapa: registros (todos) y memoria (palabras indicadas) ----
  task check_stage(input integer s, input [7:0] nom, input integer retExp, input integer cycNow);
    integer j, errs; reg [31:0] got;
    begin
      errs = 0;
      for (j = 1; j < 32; j = j + 1)
        if (sh[j] !== eR[s*32+j]) begin
          errs = errs + 1;
          $display("  [FALLO etapa %0s] x%0d = %0d, esperado %0d", nom, j, sh[j], eR[s*32+j]);
        end
      for (j = 0; j < 16; j = j + 1)
        if (eMk[s*16+j]) begin
          got = dut.dmem.RAM[BASE_IDX+j];
          if (got !== eM[s*16+j]) begin
            errs = errs + 1;
            $display("  [FALLO etapa %0s] M[x1+%0d] = %0d, esperado %0d", nom, j*4, got, eM[s*16+j]);
          end
        end
      if (retired !== retExp) begin
        errs = errs + 1;
        $display("  [AVISO etapa %0s] instrucciones retiradas = %0d, esperado %0d (emulador ISA)", nom, retired, retExp);
      end
      etapa_cerrada[s] = 1; etapa_pulso[s] = 1; etapa_ok[s] = (errs == 0);
      errs_total = errs_total + errs;
      if (errs == 0) $display("ETAPA %0s cerrada en el ciclo %0d (retiradas=%0d): OK", nom, cycNow, retired);
      else           $display("ETAPA %0s cerrada en el ciclo %0d (retiradas=%0d): FALLO", nom, cycNow, retired);
    end
  endtask

  // ---- retiro de una instruccion: actualiza el banco sombra y comprueba si cierra una etapa ----
  task retire(input [31:0] pc, input rw, input [4:0] rd, input [31:0] res);
    begin
      retired = retired + 1;
      if (rw && rd != 0) sh[rd] = res;
      if (pc === PC_A) begin cyc_A = cyc; check_stage(0, "A", RET_A, cyc); end
      if (pc === PC_B) begin cyc_B = cyc; check_stage(1, "B", RET_B, cyc); end
      if (pc === PC_C) begin cyc_C = cyc; check_stage(2, "C", RET_C, cyc); end
      if (pc === PC_D) begin cyc_D = cyc; check_stage(3, "D", RET_D, cyc); done = 1; end
    end
  endtask

  // ---- bucle principal: se evalua en el flanco de bajada de cada ciclo (despues de reset) ----
  always @(negedge clk) if (!reset && !done) begin
    cyc = cyc + 1;
    etapa_pulso = 0;
`ifndef SINGLE
    // causas de emision en Decode de este ciclo
    if (dut.rvpipeline.Issue1)                                         c_dual = c_dual + 1;
    else if (dut.rvpipeline.Issue0)                                    c_single = c_single + 1;
    if (!dut.rvpipeline.ValidD0)                                       c_bubble = c_bubble + 1;
    if (dut.rvpipeline.ValidD0 && dut.rvpipeline.LoadUse0)             c_stall_lu0 = c_stall_lu0 + 1;
    if (dut.rvpipeline.Issue0 && dut.rvpipeline.ValidD1 && dut.rvpipeline.RawPair)      c_raw  = c_raw + 1;
    if (dut.rvpipeline.Issue0 && dut.rvpipeline.ValidD1 && dut.rvpipeline.CtrlConflict) c_ctrl = c_ctrl + 1;
    if (dut.rvpipeline.Issue0 && dut.rvpipeline.ValidD1 && dut.rvpipeline.LoadUse1)     c_lu1  = c_lu1 + 1;
    if (dut.rvpipeline.Issue0 && dut.rvpipeline.ValidD1 && dut.rvpipeline.MemConflict && !dut.rvpipeline.Issue1)
                                                                       c_memblk = c_memblk + 1;
    if (dut.rvpipeline.ValidD0 && dut.rvpipeline.ValidD1 && dut.rvpipeline.MemConflict) c_mem2 = c_mem2 + 1;
    if (dut.rvpipeline.Issue1 && dut.rvpipeline.MemConflict)           c_mem2pair = c_mem2pair + 1;
    if (dut.rvpipeline.FlushD)                                         c_flush = c_flush + 1;
`endif
    // retiro: via 0 (mas antigua) y luego via 1; si la via 0 cierra D, la via 1 (posterior) no se cuenta
    if (`V0) retire(`PC0, `RW0, `RD0, `RES0);
    if (`V1 && !done) retire(`PC1, `RW1, `RD1, `RES1);

    if (done) begin
      $display("------------------------------------------------------------");
      $display("Ciclos totales            : %0d", cyc);
      $display("Instrucciones retiradas   : %0d (esperado %0d)", retired, RET_D);
      $display("CPI                       : %0f", cyc * 1.0 / retired);
      $display("IPC                       : %0f", retired * 1.0 / cyc);
`ifndef SINGLE
      $display("-- causas de emision (un ciclo puede sumar a varias) --");
      $display("ciclos con doble emision          : %0d", c_dual);
      $display("ciclos con emision simple         : %0d", c_single);
      $display("ciclos sin instruccion valida     : %0d", c_bubble);
      $display("stalls load-use (slot 0)          : %0d", c_stall_lu0);
      $display("pares rotos por RAW               : %0d", c_raw);
      $display("pares rotos por load-use (slot 1) : %0d", c_lu1);
      $display("pares rotos por control           : %0d", c_ctrl);
      $display("pares rotos por conflicto memoria : %0d", c_memblk);
      $display("ciclos con 2 accesos a memoria en D: %0d (emparejados: %0d)", c_mem2, c_mem2pair);
      $display("flush por salto tomado            : %0d", c_flush);
`endif
      $display("RESULTADO,%0d,%0d,%0f,%0f", cyc, retired, cyc * 1.0 / retired, retired * 1.0 / cyc);
      if (errs_total == 0) $display("PRUEBA SUPERADA: A, B, C y D correctas");
      else                 $display("PRUEBA FALLIDA: %0d diferencias", errs_total);
      #1 $finish;
    end
    if (cyc >= MAX_CYC) begin
      $display("TIMEOUT: %0d ciclos, %0d instrucciones retiradas", cyc, retired);
      $finish;
    end
  end

  initial begin
    $dumpfile("tb_proyecto.vcd");
    $dumpvars(0, tb_proyecto);
  end
endmodule
