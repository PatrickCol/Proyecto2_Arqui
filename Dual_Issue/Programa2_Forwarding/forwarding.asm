# Programa 2: forwarding (cadena de dependencias RAW)
        addi x1, x0, 5
        addi x2, x0, 10
        add  x3, x1, x2
        sub  x4, x3, x1
        add  x5, x4, x3
        add  x6, x5, x4
fin:    beq  x0, x0, fin
