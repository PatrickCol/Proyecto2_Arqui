
# Programa 1 — ISA sin dependencias

Proyecto 2 — Arquitectura de Computadoras

## Objetivo

Verificar la ejecucion correcta de instrucciones
RISC-V RV32I soportadas por el procesador pipeline
de cinco etapas, utilizando secuencias que no
requieran forwarding ni stalling.

## Archivos

- isa.asm: Programa Assembly de prueba.
- isa.mem: Instrucciones en hexadecimal.
- tb_isa.v: Testbench de verificacion.

## Verificaciones

- Instrucciones tipo R: add, sub, and, or, xor, slt.
- Instrucciones con inmediato: addi, andi, ori, xori, slti.
- Memoria: sw y lw.
- Salto condicional no tomado: beq.
- Resultados esperados en los registros (x1 a x18) y en la memoria.
- Ningun forwarding, stall ni flush: la Hazard Unit no interviene.
- jal, jalr y beq tomado siempre provocan flush; se verifican en el Programa 4.

## Estado

Verificado en simulación (PASS).
