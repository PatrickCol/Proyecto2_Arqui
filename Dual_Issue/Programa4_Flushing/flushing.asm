
# PROGRAMA 4 - FLUSHING
# Arquitectura de Computadoras - E1
# Prueba de anulacion de instrucciones ante saltos (beq, jal, jalr)
# Cada salto tomado se resuelve en EX y descarta las 2 instrucciones siguientes

addi x1, x0, 5      # x1 = 5
addi x2, x0, 5      # x2 = 5
addi x3, x0, 7      # x3 = 7

beq  x1, x3, t1     # NO tomado (5 != 7): no hay flush
addi x4, x0, 1      # x4 = 1 (si se ejecuta)

beq  x1, x2, t1     # TOMADO (5 == 5): flush
addi x5, x0, 99     # descartada -> x5 = 0
addi x6, x0, 99     # descartada -> x6 = 0
t1:
addi x7, x0, 2      # x7 = 2

jal  x8, t2         # x8 = 40 (PC+4), flush
addi x9, x0, 99     # descartada -> x9 = 0
addi x10, x0, 99    # descartada -> x10 = 0
t2:
addi x11, x0, 3     # x11 = 3

addi x12, x0, 68    # x12 = 68 = direccion de t3
jalr x13, 0(x12)    # x13 = 60 (PC+4), salta a t3, flush
addi x14, x0, 99    # descartada -> x14 = 0
addi x15, x0, 99    # descartada -> x15 = 0
t3:
addi x16, x0, 4     # x16 = 4
sw   x16, 0(x0)     # Memoria[0] = 4

fin:
beq  x0, x0, fin    # bucle final
