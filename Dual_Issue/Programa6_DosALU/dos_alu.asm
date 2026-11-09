# Programa 6: dos ALU independientes salen juntas (Issue1 = 1)
        addi x1, x0, 1
        addi x2, x0, 2
        addi x3, x0, 3
        addi x4, x0, 4
        addi x5, x0, 5
        addi x6, x0, 6
        addi x7, x0, 7
        addi x8, x0, 8
        add  x9, x1, x2
        sub  x10, x3, x4
        and  x11, x5, x6
        or   x12, x7, x8
        xor  x13, x1, x3
        slt  x14, x2, x4
        addi x15, x5, 10
        addi x16, x6, 20
fin:    beq  x0, x0, fin
