// Memoria de datos de doble puerto (arquitectura C), 512 palabras (el programa del profesor usa x1 = 1536).
//  - lw/lw: lecturas independientes.
//  - sw/sw a la misma direccion: gana la via 1 (la mas joven en orden de programa).
//  - sw(via0)+lw(via1) misma direccion: la via 1 lee el dato de la via 0 (bypass interno).
//  - lw(via0)+sw(via1) misma direccion: el lw lee el valor anterior (lectura combinacional).
module dmem(input         clk, we0, we1,
            input  [31:0] a0, a1, wd0, wd1,
            output [31:0] rd0, rd1);

  reg [31:0] RAM[511:0];

  assign rd0 = RAM[a0[31:2]];
  assign rd1 = (we0 && (a0[31:2] == a1[31:2])) ? wd0 : RAM[a1[31:2]];

  always @(posedge clk) begin
    if (we0) RAM[a0[31:2]] <= wd0;
    if (we1) RAM[a1[31:2]] <= wd1;   // misma direccion: esta asignacion va despues y gana
  end
endmodule