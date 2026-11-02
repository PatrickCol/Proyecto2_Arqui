
`timescale 1ns/1ps

module tb_stalling;

    reg clk;
    reg reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;

    integer i;
    integer fd;
    integer errores;
    integer ciclos_stall;

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
        ciclos_stall = 0;

        #1;

        // Rellenar memoria con NOP
        for (i = 0; i < 64; i = i + 1)
            dut.imem.RAM[i] = 32'h00000013;

        // Cargar programa Stalling
        // Ruta relativa a la carpeta principal; en Vivado el .mem se copia
        // junto al simulador, asi que si no esta ahi se usa solo el nombre
        fd = $fopen("Programa3_Stalling/stalling.mem", "r");
        if (fd) begin
            $fclose(fd);
            $readmemh("Programa3_Stalling/stalling.mem", dut.imem.RAM);
        end else
            $readmemh("stalling.mem", dut.imem.RAM);

        #21;
        reset = 0;

        // Tiempo suficiente para ejecutar el programa
        #180;

        $display("===== RESULTADOS =====");

        // Verificacion de registros
        if (dut.rvpipeline.dp.rf.rf[1] !== 32'd0)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[2] !== 32'd10)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[3] !== 32'd10)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[4] !== 32'd20)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[5] !== 32'd10)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[6] !== 32'd20)
            errores = errores + 1;

        // Comprobar dato escrito en memoria
        if (dut.dmem.RAM[0] !== 32'd10)
            errores = errores + 1;

        // Debe observarse al menos un stall
        if (ciclos_stall == 0) begin
            $display("ERROR: No se detecto stalling");
            errores = errores + 1;
        end

        $display("Ciclos con stall: %0d",
                 ciclos_stall);

        if (errores == 0)
            $display("PASS: Stalling correcto");
        else
            $display("FAIL: %0d errores", errores);

        $finish;
    end

    // Monitor de las senales de la Hazard Unit
    always @(negedge clk) begin
        if (!reset) begin

            if (dut.rvpipeline.StallF &&
                dut.rvpipeline.StallD &&
                dut.rvpipeline.FlushE) begin

                ciclos_stall = ciclos_stall + 1;

                $display(
                    "STALL t=%0t StallF=%b StallD=%b FlushE=%b",
                    $time,
                    dut.rvpipeline.StallF,
                    dut.rvpipeline.StallD,
                    dut.rvpipeline.FlushE
                );

            end
        end
    end

    // Archivo de ondas para GTKWave o EPWave
    initial begin
        $dumpfile("stalling.vcd");
        $dumpvars(0, tb_stalling);
    end

endmodule
