
# PROGRAMA 2 - FORWARDING
# Arquitectura de Computadoras - E1
# Prueba de dependencias RAW con forwarding

addi x1, x0, 5     # x1 = 5
addi x2, x0, 10    # x2 = 10

add  x3, x1, x2    # x3 = 15
                   # Depende de x1 y x2

sub  x4, x3, x1    # x4 = 10
                   # Depende de x3

add  x5, x4, x3    # x5 = 25
                   # Depende de x4 y x3

add  x6, x5, x4    # x6 = 35
                   # Depende de x5 y x4
