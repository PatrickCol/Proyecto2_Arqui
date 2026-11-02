
`timescale 1ns/1ps

module tb_forwarding;

  reg clk;
  reg reset;

  wire [31:0] WriteData, DataAdr;
  wire MemWrite;

  integer i;
  integer fd;
  integer errores;
  integer eventos_forwarding;

  // Procesador original del grupo
  top dut (
    .clk(clk),
    .reset(reset),
    .WriteData(WriteData),
    .DataAdr(DataAdr),
    .MemWrite(MemWrite)
  );

    // Señales para el waveform: instruccion en cada etapa y Hazard Unit
    wire [31:0] PCF       = dut.rvpipeline.dp.PCF;
    wire [31:0] InstrF    = dut.rvpipeline.dp.InstrF;
    wire [31:0] InstrD    = dut.rvpipeline.dp.InstrD;
    wire [31:0] InstrE    = dut.rvpipeline.dp.InstrE;
    wire [31:0] InstrM    = dut.rvpipeline.dp.InstrM;
    wire [31:0] InstrW    = dut.rvpipeline.dp.InstrW;
    wire [31:0] ResultW   = dut.rvpipeline.dp.ResultW;
    wire        StallF    = dut.rvpipeline.StallF;
    wire        StallD    = dut.rvpipeline.StallD;
    wire        FlushD    = dut.rvpipeline.FlushD;
    wire        FlushE    = dut.rvpipeline.FlushE;
    wire [1:0]  ForwardAE = dut.rvpipeline.ForwardAE;
    wire [1:0]  ForwardBE = dut.rvpipeline.ForwardBE;
    wire [1:0]  PCSrcE    = dut.rvpipeline.PCSrcE;

  // Reloj: periodo de 10 ns
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Cargar exclusivamente el programa Forwarding
  initial begin
    reset = 1;
    errores = 0;
    eventos_forwarding = 0;

    #1;

    // Completar memoria con instrucciones NOP
    for (i = 0; i < 64; i = i + 1)
      dut.imem.RAM[i] = 32'h00000013;

    // Ruta relativa a la carpeta principal; en Vivado el .mem se copia
    // junto al simulador, asi que si no esta ahi se usa solo el nombre
    fd = $fopen("Programa2_Forwarding/forwarding.mem", "r");
    if (fd) begin
      $fclose(fd);
      $readmemh("Programa2_Forwarding/forwarding.mem", dut.imem.RAM);
    end else
      $readmemh("forwarding.mem", dut.imem.RAM);

    #21;
    reset = 0;

    // Dar tiempo a completar el pipeline
    #150;

    // Comprobar resultados finales
    if (dut.rvpipeline.dp.rf.rf[1] !== 32'd5)
      errores = errores + 1;

    if (dut.rvpipeline.dp.rf.rf[2] !== 32'd10)
      errores = errores + 1;

    if (dut.rvpipeline.dp.rf.rf[3] !== 32'd15)
      errores = errores + 1;

    if (dut.rvpipeline.dp.rf.rf[4] !== 32'd10)
      errores = errores + 1;

    if (dut.rvpipeline.dp.rf.rf[5] !== 32'd25)
      errores = errores + 1;

    if (dut.rvpipeline.dp.rf.rf[6] !== 32'd35)
      errores = errores + 1;

    if (eventos_forwarding == 0) begin
      $display("ERROR: No se observo forwarding");
      errores = errores + 1;
    end

    $display("Eventos forwarding: %0d",
             eventos_forwarding);

    if (errores == 0)
      $display("PASS: Forwarding correcto");
    else
      $display("FAIL: %0d errores", errores);

    $finish;
  end

  // Observar las señales de forwarding
  always @(posedge clk) begin
    if (!reset) begin
      if ((dut.rvpipeline.ForwardAE != 2'b00) ||
          (dut.rvpipeline.ForwardBE != 2'b00)) begin

        eventos_forwarding = eventos_forwarding + 1;

        $display(
          "Tiempo=%0t ForwardAE=%b ForwardBE=%b",
          $time,
          dut.rvpipeline.ForwardAE,
          dut.rvpipeline.ForwardBE
        );
      end
    end
  end

  // Generar archivo para visualizar waveforms
  initial begin
    $dumpfile("forwarding.vcd");
    $dumpvars(0, tb_forwarding);
  end

endmodule
