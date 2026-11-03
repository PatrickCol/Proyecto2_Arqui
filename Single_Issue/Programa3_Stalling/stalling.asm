
# PROGRAMA 3 - STALLING
# Arquitectura de Computadoras - E1
# Prueba de dependencia Load-Use

addi x1, x0, 0     # x1 = 0, direccion base de memoria
addi x2, x0, 10    # x2 = 10

sw   x2, 0(x1)     # Memoria[0] = 10

lw   x3, 0(x1)     # x3 = Memoria[0] = 10
add  x4, x3, x2    # x4 = 20
                   # Dependencia Load-Use: requiere stall

sub  x5, x4, x2    # x5 = 10
                   # Dependencia resuelta con forwarding

add  x6, x5, x3    # x6 = 20
