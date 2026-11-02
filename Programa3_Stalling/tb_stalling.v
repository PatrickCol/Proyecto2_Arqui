
`timescale 1ns/1ps

module tb_stalling;

    reg clk;
    reg reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;

    integer i;
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
        $readmemh(
            "Programa3_Stalling/stalling.mem",
            dut.imem.RAM
        );

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
