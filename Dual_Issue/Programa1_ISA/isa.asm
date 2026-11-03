
# PROGRAMA 1 - ISA SIN DEPENDENCIAS
# Arquitectura de Computadoras - E1
# Prueba de las instrucciones RV32I soportadas sin dependencias
# que requieran la Hazard Unit (sin forwarding, stall ni flush).
# jal, jalr y beq tomado siempre provocan flush: se verifican en el Programa 4.

# Inicializacion de registros
addi x4, x0, 3      # x4 = 3
addi x1, x0, 12     # x1 = 12
addi x2, x0, 5      # x2 = 5
addi x3, x0, 8      # x3 = 8

# Separacion para evitar dependencias cercanas
nop
nop
nop
nop

# Operaciones tipo R
add  x5, x1, x2     # x5 = 17
sub  x6, x3, x4     # x6 = 5
and  x7, x1, x3     # x7 = 8
or   x8, x2, x4     # x8 = 7
xor  x9, x1, x2     # x9 = 9
slt  x10, x4, x2    # x10 = 1  (3 < 5)

# Operaciones con inmediato
addi x11, x0, -5    # x11 = -5
andi x12, x1, 6     # x12 = 4  (12 & 6)
ori  x13, x2, 8     # x13 = 13 (5 | 8)
xori x14, x3, 15    # x14 = 7  (8 ^ 15)
slti x15, x2, 7     # x15 = 1  (5 < 7)

# Memoria
sw   x1, 0(x0)      # Memoria[0] = 12
sw   x2, 4(x0)      # Memoria[1] = 5
lw   x16, 0(x0)     # x16 = 12
lw   x17, 4(x0)     # x17 = 5

# Separacion
nop
nop
nop

# Salto condicional no tomado
beq  x16, x17, salto    # 12 != 5: no se toma
addi x18, x0, 1         # x18 = 1 (se ejecuta)
salto:
