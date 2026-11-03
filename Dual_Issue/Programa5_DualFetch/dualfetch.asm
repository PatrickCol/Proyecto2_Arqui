
# PROGRAMA 5 - DUAL FETCH / DUAL DECODE
# Arquitectura de Computadoras - E1
# Se leen y decodifican pares de instrucciones (PC, PC+4) y se emiten
# en orden, una por ciclo, sin perder ni repetir instrucciones

addi x1, x0, 1      # par 0x00: slot 0
addi x2, x0, 2      # par 0x00: slot 1
addi x3, x0, 3      # par 0x08: slot 0
addi x4, x0, 4      # par 0x08: slot 1
add  x5, x1, x2     # x5 = 3
add  x6, x3, x4     # x6 = 7
sw   x5, 0(x0)      # Memoria[0] = 3
sw   x6, 4(x0)      # Memoria[1] = 7

beq  x0, x0, t1     # TOMADO en slot 0: se anula el slot 1
addi x7, x0, 99     # descartada -> x7 = 0
t1:
addi x8, x0, 8      # x8 = 8

fin:
beq  x0, x0, fin    # bucle final
