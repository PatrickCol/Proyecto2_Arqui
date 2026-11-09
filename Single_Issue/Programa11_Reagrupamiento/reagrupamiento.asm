# Programa 11: emision parcial y reagrupamiento (orden preservado, sin instrucciones perdidas ni repetidas)
        addi x1, x0, 3
        add  x2, x1, x1        # RAW: sale sola, la siguiente se reagrupa
        add  x3, x2, x1
        addi x4, x0, 4         # independiente: puede emparejarse con la anterior
        add  x5, x4, x3
        sw   x5, 0(x0)
        lw   x6, 0(x0)
        sw   x6, 4(x0)         # RAW + memoria
        addi x7, x0, 7
        addi x8, x0, 8
        add  x9, x7, x8
        sub  x10, x9, x7
        sw   x10, 8(x0)
fin:    beq  x0, x0, fin
