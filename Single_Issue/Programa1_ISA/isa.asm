# Programa 1: instrucciones sin dependencias (cada resultado esta a 3 o mas instrucciones de su uso)
        addi x4, x0, 3
        addi x1, x0, 12
        addi x2, x0, 5
        addi x3, x0, 8
        nop
        nop
        nop
        nop
        add  x5, x1, x2
        sub  x6, x3, x4
        and  x7, x1, x3
        or   x8, x2, x4
        xor  x9, x1, x2
        slt  x10, x4, x2
        addi x11, x0, -5
        andi x12, x1, 6
        ori  x13, x2, 8
        xori x14, x3, 15
        slti x15, x2, 7
        sw   x1, 0(x0)
        sw   x2, 4(x0)
        lw   x16, 0(x0)
        lw   x17, 4(x0)
        nop
        nop
        nop
        beq  x16, x17, salto
        addi x18, x0, 1
salto:
fin:    beq  x0, x0, fin
