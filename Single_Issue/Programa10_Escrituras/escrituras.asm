# Programa 10: dos escrituras al Register File por ciclo y escrituras al mismo registro
        addi x1, x0, 1         # x1 y x2 se escriben en el mismo ciclo (puertos 0 y 2)
        addi x2, x0, 2
        addi x3, x0, 3
        addi x4, x0, 4
        addi x5, x0, 5         # WAW: dos escrituras al mismo registro; gana la mas joven
        addi x5, x0, 6
        addi x6, x0, 7
        addi x6, x0, 8
        add  x7, x5, x6        # 6 + 8
        add  x8, x1, x2
        sw   x7, 0(x0)
        sw   x8, 4(x0)
fin:    beq  x0, x0, fin
