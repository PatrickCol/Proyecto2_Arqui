
# Programa 4 — Flushing

Proyecto 2 — Arquitectura de Computadoras

## Objetivo

Verificar la anulacion (flush) de instrucciones del
camino incorrecto ante cambios del flujo de control
en el procesador RISC-V RV32I Pipeline de cinco etapas.

## Archivos

- flushing.asm: Programa Assembly de prueba.
- flushing.mem: Instrucciones en hexadecimal.
- tb_flushing.v: Testbench de verificación.

## Casos cubiertos

- beq no tomado: no hay flush.
- beq tomado: se anulan las 2 instrucciones siguientes.
- jal: se anulan las 2 instrucciones siguientes y se escribe PC+4.
- jalr: se anulan las 2 instrucciones siguientes y se escribe PC+4.

## Señales que se verificarán

- PCSrcE
- FlushD
- FlushE

## Estado

Verificado en simulación (PASS).
