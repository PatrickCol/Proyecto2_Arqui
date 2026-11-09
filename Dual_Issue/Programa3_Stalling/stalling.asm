# Programa 3: stalling por load-use
        addi x1, x0, 0
        addi x2, x0, 10
        sw   x2, 0(x1)
        lw   x3, 0(x1)
        add  x4, x3, x2
        sub  x5, x4, x2
        add  x6, x5, x3
fin:    beq  x0, x0, fin
