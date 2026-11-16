# Programa 15 (propio): suma de vectores, ordenamiento burbuja y rango.
# A[0..7] en 0..28, B[0..7] en 32..60, C[0..7] en 64..92. C[i] = A[i] + B[i]; luego se ordena C
# de menor a mayor y se guarda la suma de C (96) y max - min (100).
# Tiene ILP (lazo desenrollado x2), dependencias RAW y load-use, saltos tomados y
# no tomados, y pares lw+lw / sw+sw que la memoria de doble puerto puede emitir juntos.
        addi x1, x0, 0         # base A
        addi x2, x0, 1         # constante 1 (condicion de los lazos)
        addi x10, x0, 7        # A = {7, 3, 9, 1, 8, 2, 6, 4}
        addi x11, x0, 3
        addi x12, x0, 9
        addi x13, x0, 1
        addi x14, x0, 8
        addi x15, x0, 2
        addi x16, x0, 6
        addi x17, x0, 4
        sw   x10, 0(x1)
        sw   x11, 4(x1)
        sw   x12, 8(x1)
        sw   x13, 12(x1)
        sw   x14, 16(x1)
        sw   x15, 20(x1)
        sw   x16, 24(x1)
        sw   x17, 28(x1)
        addi x10, x0, 5        # B = {5, 10, 1, 12, 0, 4, 11, 3}
        addi x11, x0, 10
        addi x12, x0, 1
        addi x13, x0, 12
        addi x14, x0, 0
        addi x15, x0, 4
        addi x16, x0, 11
        addi x17, x0, 3
        sw   x10, 32(x1)
        sw   x11, 36(x1)
        sw   x12, 40(x1)
        sw   x13, 44(x1)
        sw   x14, 48(x1)
        sw   x15, 52(x1)
        sw   x16, 56(x1)
        sw   x17, 60(x1)
# ---- 1) C[i] = A[i] + B[i], desenrollado x2, y suma total ----
        addi x3, x0, 0         # p = &A[i]
        addi x5, x0, 64        # r = &C[i]
        addi x6, x0, 0         # suma
        addi x7, x0, 32        # limite de p
V:      lw   x10, 0(x3)         # A[i]
        lw   x11, 32(x3)        # B[i]
        lw   x12, 4(x3)         # A[i+1]
        lw   x13, 36(x3)        # B[i+1]
        add  x14, x10, x11
        add  x15, x12, x13
        sw   x14, 0(x5)
        sw   x15, 4(x5)
        add  x6, x6, x14
        add  x6, x6, x15
        addi x3, x3, 8
        addi x5, x5, 8
        slt  x8, x3, x7
        beq  x8, x2, V
        sw   x6, 96(x0)
# ---- 2) ordenamiento burbuja de C (7 pasadas) ----
        addi x20, x0, 7        # pasadas restantes
        addi x22, x0, 92       # ultima posicion j+1
S1:     addi x21, x0, 64       # j
S2:     lw   x10, 0(x21)
        lw   x11, 4(x21)
        slt  x8, x11, x10      # C[j+1] < C[j] ?
        beq  x8, x0, NS
        sw   x11, 0(x21)       # intercambio: dos stores en el mismo par
        sw   x10, 4(x21)
NS:     addi x21, x21, 4
        slt  x8, x21, x22
        beq  x8, x2, S2
        addi x20, x20, -1
        slt  x8, x0, x20
        beq  x8, x2, S1
# ---- 3) rango = max - min ----
        lw   x10, 64(x0)
        lw   x11, 92(x0)
        sub  x12, x11, x10
        sw   x12, 100(x0)
fin:    beq  x0, x0, fin
