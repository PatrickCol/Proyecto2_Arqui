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
