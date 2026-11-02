
`timescale 1ns/1ps

module tb_flushing;

    reg clk;
    reg reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;

    integer i;
    integer fd;
    integer errores;
    integer ciclos_flush;
    integer ciclos_stall;

    reg [31:0] esperado [0:16];

    // Procesador original del proyecto
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

    // Reloj de periodo 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Carga del programa de prueba
    initial begin
        reset = 1;
        errores = 0;
        ciclos_flush = 0;
        ciclos_stall = 0;

        // Valores finales esperados (99 = instruccion que debio anularse)
        esperado[0]  = 0;  esperado[1]  = 5;  esperado[2]  = 5;
        esperado[3]  = 7;  esperado[4]  = 1;  esperado[5]  = 0;
        esperado[6]  = 0;  esperado[7]  = 2;  esperado[8]  = 40;
        esperado[9]  = 0;  esperado[10] = 0;  esperado[11] = 3;
        esperado[12] = 68; esperado[13] = 60; esperado[14] = 0;
        esperado[15] = 0;  esperado[16] = 4;

        #1;

        // Rellenar memoria con NOP
        for (i = 0; i < 64; i = i + 1)
            dut.imem.RAM[i] = 32'h00000013;

        // Cargar programa Flushing
        // Ruta relativa a la carpeta principal; en Vivado el .mem se copia
        // junto al simulador, asi que si no esta ahi se usa solo el nombre
        fd = $fopen("Programa4_Flushing/flushing.mem", "r");
        if (fd) begin
            $fclose(fd);
            $readmemh("Programa4_Flushing/flushing.mem", dut.imem.RAM);
        end else
            $readmemh("flushing.mem", dut.imem.RAM);

        #21;
        reset = 0;

        // Tiempo suficiente para ejecutar el programa
        #300;

        $display("===== RESULTADOS =====");

        // Verificacion de registros
        for (i = 1; i <= 16; i = i + 1)
            if (dut.rvpipeline.dp.rf.rf[i] !== esperado[i]) begin
                $display("ERROR: x%0d = %0d (esperado %0d)",
                         i, dut.rvpipeline.dp.rf.rf[i], esperado[i]);
                errores = errores + 1;
            end

        // Comprobar dato escrito en memoria
        if (dut.dmem.RAM[0] !== 32'd4)
            errores = errores + 1;

        // Deben observarse exactamente 3 flushes: beq tomado, jal y jalr
        if (ciclos_flush != 3) begin
            $display("ERROR: flushes = %0d (esperado 3)", ciclos_flush);
            errores = errores + 1;
        end

        // Ningun stall en este programa
        if (ciclos_stall != 0) begin
            $display("ERROR: Stall inesperado");
            errores = errores + 1;
        end

        $display("Ciclos con flush: %0d", ciclos_flush);

        if (errores == 0)
            $display("PASS: Flushing correcto");
        else
            $display("FAIL: %0d errores", errores);

        $finish;
    end

    // Monitor de las senales de la Hazard Unit
    // Se excluye el bucle final (beq en 0x4C), que salta a si mismo indefinidamente
    always @(negedge clk) begin
        if (!reset) begin

            if (dut.rvpipeline.FlushD &&
                dut.rvpipeline.dp.PCE != 32'h4C) begin

                ciclos_flush = ciclos_flush + 1;

                $display(
                    "FLUSH t=%0t PCE=%h PCSrcE=%b FlushD=%b FlushE=%b",
                    $time,
                    dut.rvpipeline.dp.PCE,
                    dut.rvpipeline.PCSrcE,
                    dut.rvpipeline.FlushD,
                    dut.rvpipeline.FlushE
                );

            end

            if (dut.rvpipeline.StallF)
                ciclos_stall = ciclos_stall + 1;
        end
    end

    // Archivo de ondas para GTKWave o EPWave
    initial begin
        $dumpfile("flushing.vcd");
        $dumpvars(0, tb_flushing);
    end

endmodule
