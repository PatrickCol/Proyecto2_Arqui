// Mux de 5 entradas para el forwarding de las dos vias (selector de 3 bits)
//   000 = registro | 001 = WB via 0 | 010 = WB via 1 | 011 = MEM via 0 | 100 = MEM via 1
module mux5 #(parameter WIDTH = 8)
             (input      [WIDTH-1:0] d0, d1, d2, d3, d4,
              input      [2:0]       s,
              output reg [WIDTH-1:0] y);

  always @* case (s)
    3'b000:  y = d0;
    3'b001:  y = d1;
    3'b010:  y = d2;
    3'b011:  y = d3;
    3'b100:  y = d4;
    default: y = d0;
  endcase
endmodule
