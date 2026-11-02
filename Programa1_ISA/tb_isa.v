
`timescale 1ns/1ps

module tb_isa;

    reg clk;
    reg reset;

    wire [31:0] WriteData;
    wire [31:0] DataAdr;
    wire MemWrite;

    integer i;
    integer errores;
    integer ciclos_stall;

    // Procesador original del grupo
    top dut (
        .clk(clk),
        .reset(reset),
        .WriteData(WriteData),
        .DataAdr(DataAdr),
        .MemWrite(MemWrite)
    );

    // Reloj de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        errores = 0;
        ciclos_stall = 0;

        #1;

        // Inicializar memoria con NOP
        for (i = 0; i < 64; i = i + 1)
            dut.imem.RAM[i] = 32'h00000013;

        // Cargar el Programa 1
        $readmemh(
            "Programa1_ISA/isa.mem",
            dut.imem.RAM
        );

        #21;
        reset = 0;

        // Permitir completar las instrucciones
        #300;

        $display("===== RESULTADOS ISA =====");

        // Verificar registros
        if (dut.rvpipeline.dp.rf.rf[1] !== 32'd12)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[2] !== 32'd5)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[3] !== 32'd8)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[4] !== 32'd3)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[5] !== 32'd17)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[6] !== 32'd5)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[7] !== 32'd8)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[8] !== 32'd7)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[9] !== 32'd9)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[10] !== 32'd20)
            errores = errores + 1;

        if (dut.rvpipeline.dp.rf.rf[11] !== 32'hFFFFFFFB)
            errores = errores + 1;

        // No deben existir stalls en este programa
        if (ciclos_stall != 0) begin
            $display("ERROR: Stall inesperado");
            errores = errores + 1;
        end

        $display("Ciclos con stall: %0d",
                 ciclos_stall);

        if (errores == 0)
            $display("PASS: ISA sin dependencias");
        else
            $display("FAIL: %0d errores", errores);

        $finish;
    end

    // Monitor de stalls
    always @(negedge clk) begin
        if (!reset) begin
            if (dut.rvpipeline.StallF ||
                dut.rvpipeline.StallD)
                ciclos_stall = ciclos_stall + 1;
        end
    end

    // Waveforms para el informe E1
    initial begin
        $dumpfile("isa.vcd");
        $dumpvars(0, tb_isa);
    end

endmodule
