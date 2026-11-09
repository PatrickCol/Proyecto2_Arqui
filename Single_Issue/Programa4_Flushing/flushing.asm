# Programa 4: flushing (beq no tomado, beq tomado, jal, jalr)
        addi x1, x0, 5
        addi x2, x0, 5
        addi x3, x0, 7
        beq  x1, x3, t1
        addi x4, x0, 1
        beq  x1, x2, t1
        addi x5, x0, 99
        addi x6, x0, 99
t1:     addi x7, x0, 2
        jal  x8, t2
        addi x9, x0, 99
        addi x10, x0, 99
t2:     addi x11, x0, 3
        addi x12, x0, 68
        jalr x13, 0(x12)
        addi x14, x0, 99
        addi x15, x0, 99
t3:     addi x16, x0, 4
        sw   x16, 0(x0)
fin:    beq  x0, x0, fin
