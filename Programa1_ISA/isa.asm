
# PROGRAMA 1 - ISA SIN DEPENDENCIAS
# Arquitectura de Computadoras - E1
# Prueba basica de instrucciones RV32I

# Inicializacion de registros
addi x1, x0, 12    # x1 = 12
addi x2, x0, 5     # x2 = 5
addi x3, x0, 8     # x3 = 8
addi x4, x0, 3     # x4 = 3

# Separacion para evitar dependencias cercanas
nop
nop
nop
nop

# Operaciones aritmeticas y logicas
add  x5, x1, x2    # x5 = 17
sub  x6, x3, x4    # x6 = 5
and  x7, x1, x3    # x7 = 8
or   x8, x2, x4    # x8 = 7
xor  x9, x1, x2    # x9 = 9

# Separacion
nop
nop
nop
nop

# Operaciones inmediatas
addi x10, x0, 20   # x10 = 20
addi x11, x0, -5   # x11 = -5
