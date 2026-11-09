Primera parte
=====================================

Creamos un procesador Pipeline funcional, capaz de afrontar dependencias como Forwarding, Stalling o Flushing.

## Etapa 1 — Pipeline Single-Issue (arquitectura A)

| Programa | Prueba | Resultado |
|---|---|---|
| Programa1_ISA | Instrucciones sin dependencias | PASS, 0 stalls |
| Programa2_Forwarding | RAW resueltas con forwarding (MEM y WB) | PASS, 4 eventos |
| Programa3_Stalling | Load-Use | PASS, 1 stall |
| Programa4_Flushing | beq no tomado / tomado, jal, jalr | PASS, 3 flushes |

## Etapa 2 — Dual-Issue In-Order (arquitectura B)

Cada testbench verifica orden de retiro, registros, memoria y un mínimo de pares retirados (`MIN_PAIRS`).

| Programa | Prueba |
|---|---|
| Programa5_DualFetch | Dual Fetch, Dual Decode y orden de emisión |
| Programa6_DosALU | Dos ALU independientes emitidas juntas |
| Programa7_RAW_Forwarding | RAW dentro del par y forwarding entre vías y etapas |
| Programa8_Load_Memoria | Load-Use y conflictos del puerto de memoria |
| Programa9_Branches | Branches tomados y no tomados, jal y jalr |
| Programa10_Escrituras | Dos escrituras al Register File y escrituras al mismo registro |
| Programa11_Reagrupamiento | Emisión parcial, reagrupamiento y orden |
| Programa12_Benchmark | Lazos: comparación de ciclos e IPC |
| Programa13_Casos_Via1 | Load-Use en slot 1, branch no tomado y jalr en vía 1, x0 |
