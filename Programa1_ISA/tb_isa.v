
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
    integer ciclos_flush;
    integer ciclos_forward;

    reg [31:0] esperado [0:18];

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

    // Reloj de 10 ns
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        reset = 1;
        errores = 0;
        ciclos_stall = 0;
        ciclos_flush = 0;
        ciclos_forward = 0;

        // Valores finales esperados de x1 a x18
        esperado[1]  = 12;  esperado[2]  = 5;   esperado[3]  = 8;
        esperado[4]  = 3;   esperado[5]  = 17;  esperado[6]  = 5;
        esperado[7]  = 8;   esperado[8]  = 7;   esperado[9]  = 9;
        esperado[10] = 1;   esperado[11] = -5;  esperado[12] = 4;
        esperado[13] = 13;  esperado[14] = 7;   esperado[15] = 1;
        esperado[16] = 12;  esperado[17] = 5;   esperado[18] = 1;

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
        #400;

        $display("===== RESULTADOS ISA =====");

        // Verificar registros
        for (i = 1; i <= 18; i = i + 1)
            if (dut.rvpipeline.dp.rf.rf[i] !== esperado[i]) begin
                $display("ERROR: x%0d = %0d (esperado %0d)",
                         i, $signed(dut.rvpipeline.dp.rf.rf[i]), $signed(esperado[i]));
                errores = errores + 1;
            end

        // Verificar memoria (sw)
        if (dut.dmem.RAM[0] !== 32'd12 || dut.dmem.RAM[1] !== 32'd5) begin
            $display("ERROR: memoria incorrecta");
            errores = errores + 1;
        end

        // Ninguna instruccion debe requerir la Hazard Unit
        if (ciclos_stall != 0 || ciclos_flush != 0 || ciclos_forward != 0) begin
            $display("ERROR: la Hazard Unit intervino");
            errores = errores + 1;
        end

        $display("Ciclos con stall: %0d | flush: %0d | forwarding: %0d",
                 ciclos_stall, ciclos_flush, ciclos_forward);

        if (errores == 0)
            $display("PASS: ISA sin dependencias");
        else
            $display("FAIL: %0d errores", errores);

        $finish;
    end

    // Monitor de la Hazard Unit
    always @(negedge clk) begin
        if (!reset) begin
            if (StallF || StallD)
                ciclos_stall = ciclos_stall + 1;
            if (FlushD || FlushE)
                ciclos_flush = ciclos_flush + 1;
            if (ForwardAE != 2'b00 || ForwardBE != 2'b00)
                ciclos_forward = ciclos_forward + 1;
        end
    end

    // Waveforms para el informe E1
    initial begin
        $dumpfile("isa.vcd");
        $dumpvars(0, tb_isa);
    end

endmodule
