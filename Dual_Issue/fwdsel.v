// Selector de forwarding para UN operando de una via (en EX).
// Gana el productor MAS RECIENTE: MEM via 1 > MEM via 0 > WB via 1 > WB via 0 > Register File
//   100 = ALUResultM1 | 011 = ALUResultM0 | 010 = ResultW1 | 001 = ResultW0 | 000 = registro
module fwdsel(input  [4:0] Rs,
              input  [4:0] RdM0, RdM1, RdW0, RdW1,
              input        RegWriteM0, RegWriteM1, RegWriteW0, RegWriteW1,
              output reg [2:0] Forward);

  always @* begin
    if      ((Rs != 5'b0) && RegWriteM1 && (Rs == RdM1)) Forward = 3'b100;
    else if ((Rs != 5'b0) && RegWriteM0 && (Rs == RdM0)) Forward = 3'b011;
    else if ((Rs != 5'b0) && RegWriteW1 && (Rs == RdW1)) Forward = 3'b010;
    else if ((Rs != 5'b0) && RegWriteW0 && (Rs == RdW0)) Forward = 3'b001;
    else                                                 Forward = 3'b000;
  end
endmodule
