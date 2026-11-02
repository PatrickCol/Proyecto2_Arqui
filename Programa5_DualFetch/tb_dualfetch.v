
`timescale 1ns/1ps

module tb_dualfetch;

    reg clk;
    reg reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;

    integer i;
    integer errores;
    integer pares_leidos;
    integer n_emitidas;

    reg [31:0] esperado [0:8];
    reg [31:0] orden    [0:10];   // orden en que deben llegar a EX
    reg [31:0] PCprev;
    reg        saltoPrev;
    reg [31:0] destinoPrev;

    // Procesador del proyecto
    top dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    // Senales para el waveform: par en Fetch/Decode y etapas del pipeline
    wire [31:0] PCF       = dut.rvpipeline.dp.PCF;
    wire [31:0] InstrF    = dut.rvpipeline.dp.InstrF;
    wire [31:0] InstrF1   = dut.rvpipeline.dp.InstrF1;
    wire [31:0] InstrD0   = dut.rvpipeline.dp.InstrD0;
    wire [31:0] InstrD1   = dut.rvpipeline.dp.InstrD1;
    wire        SelD      = dut.rvpipeline.dp.SelD;
    wire [31:0] InstrD    = dut.rvpipeline.dp.InstrD;
    wire [31:0] InstrE    = dut.rvpipeline.dp.InstrE;
    wire [31:0] InstrM    = dut.rvpipeline.dp.InstrM;
    wire [31:0] InstrW    = dut.rvpipeline.dp.InstrW;
    wire [31:0] ResultW   = dut.rvpipeline.dp.ResultW;
    wire        FlushD    = dut.rvpipeline.FlushD;
    wire        FlushE    = dut.rvpipeline.FlushE;
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
        pares_leidos = 0;
        n_emitidas = 0;

        esperado[1] = 1; esperado[2] = 2; esperado[3] = 3;
        esperado[4] = 4; esperado[5] = 3; esperado[6] = 7;
        esperado[7] = 0; esperado[8] = 8;

        // Todas menos 0x24 (anulada por el beq), en orden de programa
        orden[0] = 32'h00100093; orden[1]  = 32'h00200113;
        orden[2] = 32'h00300193; orden[3]  = 32'h00400213;
        orden[4] = 32'h002082B3; orden[5]  = 32'h00418333;
        orden[6] = 32'h00502023; orden[7]  = 32'h00602223;
        orden[8] = 32'h00000463; orden[9]  = 32'h00800413;
        orden[10] = 32'h00000063;

        #1;

        // Rellenar memoria con NOP
        for (i = 0; i < 64; i = i + 1)
            dut.imem.RAM[i] = 32'h00000013;

        // Cargar programa Dual Fetch
        $readmemh(
            "Programa5_DualFetch/dualfetch.mem",
            dut.imem.RAM
        );

        #21;
        reset = 0;

        // Tiempo suficiente para ejecutar el programa
        #250;

        $display("===== RESULTADOS =====");

        // Verificacion de registros
        for (i = 1; i <= 8; i = i + 1)
            if (dut.rvpipeline.dp.rf.rf[i] !== esperado[i]) begin
                $display("ERROR: x%0d = %0d (esperado %0d)",
                         i, dut.rvpipeline.dp.rf.rf[i], esperado[i]);
                errores = errores + 1;
            end

        // Comprobar datos escritos en memoria
        if (dut.dmem.RAM[0] !== 32'd3 || dut.dmem.RAM[1] !== 32'd7)
            errores = errores + 1;

        // Todas las instrucciones llegaron a EX, una sola vez y en orden
        if (n_emitidas < 11) begin
            $display("ERROR: solo %0d de 11 instrucciones llegaron a EX", n_emitidas);
            errores = errores + 1;
        end

        $display("Pares leidos por el Dual Fetch: %0d", pares_leidos);

        if (errores == 0)
            $display("PASS: Dual Fetch y Dual Decode correctos");
        else
            $display("FAIL: %0d errores", errores);

        $finish;
    end

    // Monitor del Dual Fetch y del orden de emision
    always @(negedge clk) begin
        if (!reset) begin

            // El par leido siempre es (PC, PC+4)
            if (InstrF !== dut.imem.RAM[PCF[31:2]] ||
                InstrF1 !== dut.imem.RAM[PCF[31:2] + 1]) begin
                $display("ERROR: par incorrecto en PCF=%h", PCF);
                errores = errores + 1;
            end

            // Sin salto, el PC avanza de 8 en 8
            if (PCF !== PCprev) begin
                pares_leidos = pares_leidos + 1;
                if (!saltoPrev && PCF !== PCprev + 8) begin
                    $display("ERROR: PC paso de %h a %h", PCprev, PCF);
                    errores = errores + 1;
                end
            end

            // Despues de un salto tomado, el PC debe ser el destino del salto
            if (saltoPrev === 1'b1 && PCF !== destinoPrev) begin
                $display("ERROR: tras el salto PCF=%h (esperado %h)", PCF, destinoPrev);
                errores = errores + 1;
            end

            // Cada instruccion valida que llega a EX debe ser la siguiente del programa
            if (InstrE !== 32'h0 && InstrE !== 32'h00000013 && n_emitidas < 11) begin
                if (InstrE !== orden[n_emitidas]) begin
                    $display("ERROR: en EX %h (esperado %h)", InstrE, orden[n_emitidas]);
                    errores = errores + 1;
                end
                n_emitidas = n_emitidas + 1;
            end

            PCprev    = PCF;
            saltoPrev   = (PCSrcE != 2'b00);
            destinoPrev = dut.rvpipeline.dp.PCNextF;
        end
    end

    // Archivo de ondas para GTKWave o EPWave
    initial begin
        $dumpfile("dualfetch.vcd");
        $dumpvars(0, tb_dualfetch);
    end

endmodule
