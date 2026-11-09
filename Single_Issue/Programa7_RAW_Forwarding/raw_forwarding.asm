# Programa 7: RAW dentro del par (no se emparejan) y forwarding entre vias y etapas
        addi x1, x0, 5
        addi x2, x0, 7
        add  x3, x1, x2        # usa x1 y x2 recien calculados: forwarding
        add  x4, x3, x1        # RAW con la instruccion anterior (x3)
        sub  x5, x4, x3
        and  x6, x5, x4
        or   x7, x6, x5
        xor  x8, x7, x6
        slt  x9, x8, x7
        addi x10, x0, 10       # dos escrituras al mismo registro: gana la mas joven
        addi x10, x0, 20
        add  x11, x10, x10     # debe leer 20
        add  x12, x11, x9
        add  x13, x12, x11
        sw   x13, 0(x0)
fin:    beq  x0, x0, fin
