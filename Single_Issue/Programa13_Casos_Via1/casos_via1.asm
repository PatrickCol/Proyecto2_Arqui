# Programa 13: casos de la via 1 y de x0 que faltaban (enunciado 5.1 y rubrica 3.2)
        addi x1, x0, 5
        addi x2, x0, 9
        sw   x1, 0(x0)
        addi x10, x0, 1
        sw   x2, 4(x0)
        addi x11, x0, 2
# Load-Use en el slot 1 con el lw en la via 0 (rs1)
        lw   x3, 0(x0)
        addi x12, x0, 3
        addi x13, x0, 4
        add  x14, x3, x1       # slot 1 espera al lw; el slot 0 sale solo
        addi x15, x0, 6
# Load-Use en el slot 1 con el lw en la via 1 (rs2)
        addi x16, x0, 7
        lw   x4, 4(x0)
        addi x17, x0, 8
        add  x18, x2, x4       # slot 1 espera al lw de la via 1
        addi x19, x0, 10
# Branch NO tomado en la via 1
        addi x20, x0, 11
        beq  x1, x2, malo
        addi x21, x0, 12
        addi x22, x0, 13
# Branch tomado + jalr en el mismo par: un solo resolutor de saltos
        beq  x0, x0, t1
        jalr x23, 0(x22)       # camino equivocado
        addi x23, x0, 99
# RAW por rs2 hacia un beq en el slot 1
t1:     addi x2, x0, 5
        beq  x1, x2, t2        # debe ver x2 = 5 y saltar
        addi x25, x0, 99
# jalr en la via 1: la via 0 se conserva, lo mas joven se anula y el enlace es PC+4
t2:     addi x24, x0, 132
        addi x26, x0, 14
        addi x27, x0, 15
        jalr x28, 0(x24)
        addi x29, x0, 99
        addi x30, x0, 99
malo:   addi x31, x0, 99
# Escrituras a x0: no bloquean el par ni se adelantan
t3:     addi x0, x0, 77
        add  x5, x0, x1        # lee x0 = 0 y se empareja
        add  x6, x0, x1        # con x0 en MEM debe seguir leyendo 0
        addi x7, x0, 16
# sw joven en el camino equivocado: no debe escribir
        beq  x0, x0, t4
        sw   x1, 8(x0)
        addi x8, x0, 99
t4:     sw   x18, 12(x0)
fin:    beq  x0, x0, fin
