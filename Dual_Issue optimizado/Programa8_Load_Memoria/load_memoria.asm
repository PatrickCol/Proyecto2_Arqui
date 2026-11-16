# Programa 8: load-use y conflictos del puerto de memoria
        addi x1, x0, 11
        addi x2, x0, 22
        sw   x1, 0(x0)
        sw   x2, 4(x0)         # sw + sw: un solo puerto, no se emparejan
        lw   x3, 0(x0)
        add  x4, x1, x2        # lw + ALU independiente: pueden salir juntas
        add  x5, x1, x1
        lw   x6, 4(x0)         # ALU + lw: tambien en el otro orden
        add  x7, x6, x3        # load-use: depende del lw anterior
        sub  x8, x7, x3
        sw   x8, 8(x0)
        lw   x9, 8(x0)
        addi x10, x9, 1        # load-use inmediato
        add  x11, x10, x4
        sw   x11, 12(x0)
fin:    beq  x0, x0, fin
