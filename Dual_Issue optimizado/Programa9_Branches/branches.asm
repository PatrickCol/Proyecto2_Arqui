# Programa 9: branches en cualquiera de las dos posiciones del par, tomados y no tomados, jal y jalr
        addi x1, x0, 1
        addi x2, x0, 1
        addi x3, x0, 2
        beq  x1, x3, ta        # no tomado
        addi x4, x0, 4
        beq  x1, x2, tb        # tomado: se anula solo lo mas joven
        addi x5, x0, 99
        addi x6, x0, 99
tb:     addi x7, x0, 7
        addi x8, x0, 8
        beq  x7, x8, tc        # no tomado
        addi x9, x0, 9
        nop
        beq  x1, x2, td        # tomado (otra posicion dentro del par)
        addi x11, x0, 99
        addi x12, x0, 99
ta:     addi x13, x0, 99
tc:     addi x14, x0, 99
td:     addi x15, x0, 15
        jal  x16, te           # salto incondicional
        addi x17, x0, 99
        addi x18, x0, 99
te:     addi x19, x0, 104
        jalr x20, 0(x19)       # salto indirecto
        addi x21, x0, 99
        addi x22, x0, 99
tf:     addi x23, x0, 23
        sw   x23, 0(x0)
fin:    beq  x0, x0, fin
