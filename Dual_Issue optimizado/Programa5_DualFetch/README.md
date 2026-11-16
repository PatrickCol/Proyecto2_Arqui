
# Programa 5 — Dual Fetch y Dual Decode

Proyecto 2 — Arquitectura de Computadoras

## Objetivo

Evidenciar el inicio de la arquitectura Dual-Issue:
lectura (Dual Fetch) y decodificacion (Dual Decode)
de un par de instrucciones por ciclo.

## Archivos

- dualfetch.asm: Programa Assembly de prueba.
- dualfetch.mem: Instrucciones en hexadecimal.
- tb_dualfetch.v: Testbench de verificación.

## Verificaciones

- El par leido siempre es (PC, PC+4).
- Sin saltos, el PC avanza de 8 en 8.
- Las instrucciones llegan a EX en orden, sin perderse ni repetirse.
- Un salto tomado en el slot 0 anula la instruccion del slot 1.

## Señales que se verificarán

- PCF, InstrF, InstrF1
- InstrD0, InstrD1, SelD
- InstrE, InstrM, InstrW

## Estado

Verificado en simulación (PASS).
