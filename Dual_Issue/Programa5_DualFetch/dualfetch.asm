# Programa 5: Dual Fetch / Dual Decode (programa de E1)
        addi x1, x0, 1
        addi x2, x0, 2
        addi x3, x0, 3
        addi x4, x0, 4
        add  x5, x1, x2
        add  x6, x3, x4
        sw   x5, 0(x0)
        sw   x6, 4(x0)
        beq  x0, x0, t1
        addi x7, x0, 99
t1:     addi x8, x0, 8
fin:    beq  x0, x0, fin
