# Programa 14: memoria de datos de doble puerto (optimizacion, arquitectura C)
# Cada par de accesos a memoria va en la misma pareja de Decode. En B se separa
# (MemConflict); en C se emite junto. Los resultados deben ser iguales en A, B y C.
        addi x1, x0, 10
        addi x2, x0, 20
        addi x3, x0, 30
        addi x4, x0, 40
        sw   x1, 0(x0)         # caso 1: sw + sw a direcciones distintas
        sw   x2, 4(x0)
        lw   x5, 0(x0)         # caso 2: lw + lw (dos lecturas independientes)
        lw   x6, 4(x0)
        sw   x3, 8(x0)         # caso 3: sw (via 0) + lw (via 1) a la MISMA direccion:
        lw   x7, 8(x0)         #   bypass interno, x7 = 30 (no el valor viejo 0)
        lw   x8, 0(x0)         # caso 4: lw (via 0) + sw (via 1) a la misma direccion:
        sw   x4, 0(x0)         #   el lw lee el valor anterior, x8 = 10; M[0] = 40
        sw   x1, 12(x0)        # caso 5: sw + sw a la misma direccion:
        sw   x2, 12(x0)        #   gana la mas joven (via 1), M[12] = 20
        lw   x9, 4(x0)         # caso 6: lw + ALU y ALU + sw (ya permitido en B)
        add  x10, x1, x2
        add  x11, x3, x4
        sw   x3, 16(x0)
        add  x12, x5, x6       # load-use con los loads del caso 2 ya resueltos
        add  x13, x7, x8       # usa el bypass (30) y el valor viejo (10): 40
        lw   x14, 12(x0)       # comprueba el ganador del caso 5 (20)
        lw   x15, 0(x0)        # comprueba el sw del caso 4 (40)
        add  x16, x14, x15
        sw   x16, 20(x0)
fin:    beq  x0, x0, fin
