# Programa 12: benchmark con lazos (llena un arreglo de 8 palabras con 3*i y lo suma)
        addi x1, x0, 0         # i
        addi x2, x0, 8         # n
        addi x3, x0, 0         # puntero (bytes)
fill:   add  x5, x1, x1
        add  x4, x5, x1        # 3*i
        sw   x4, 0(x3)
        addi x3, x3, 4
        addi x1, x1, 1
        beq  x1, x2, sum0
        jal  x0, fill
sum0:   addi x1, x0, 0
        addi x6, x0, 0         # suma
        addi x3, x0, 0
sumlp:  lw   x7, 0(x3)
        add  x6, x6, x7
        addi x3, x3, 4
        addi x1, x1, 1
        beq  x1, x2, done
        jal  x0, sumlp
done:   sw   x6, 64(x0)        # 3*(0+1+...+7) = 84
fin:    beq  x0, x0, fin
