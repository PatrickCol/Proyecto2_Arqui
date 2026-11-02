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

## Dual-Issue preliminar (rama dual-issue)

- Dual Fetch: imem con dos puertos de lectura (PC y PC+4), el PC avanza de 8 en 8.
- Registro IF/ID doble: guarda el par de instrucciones.
- Dual Decode: dos maindec, dos aludec y dos extend.
- Register File de 4 lecturas y 2 escrituras (la escritura de la vía 1 se conecta en E2).
- Por ahora se emite una instrucción por ciclo (SelD elige el slot), en orden de programa.

| Programa | Prueba | Resultado |
|---|---|---|
| Programa5_DualFetch | Dual Fetch, Dual Decode y orden de emisión | PASS |
