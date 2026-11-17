#!/usr/bin/env python3
# Filtro de GTKWave (Translate Filter Process): lee valores hex de 32 bits y
# devuelve la instruccion RV32I desensamblada (subconjunto del procesador).
import sys

R = {(0, 0): 'add', (0, 0x20): 'sub', (2, 0): 'slt', (4, 0): 'xor', (6, 0): 'or', (7, 0): 'and'}
I = {0: 'addi', 2: 'slti', 4: 'xori', 6: 'ori', 7: 'andi'}

def sx(v, b): return v - (1 << b) if v >> (b - 1) & 1 else v

def dis(w):
    if w == 0: return '(burbuja)'
    if w == 0x13: return 'nop'
    op, rd, f3 = w & 0x7f, w >> 7 & 31, w >> 12 & 7
    rs1, rs2, f7 = w >> 15 & 31, w >> 20 & 31, w >> 25
    iimm = sx(w >> 20, 12)
    if op == 0x33 and (f3, f7) in R: return f'{R[f3, f7]} x{rd},x{rs1},x{rs2}'
    if op == 0x13 and f3 in I: return f'{I[f3]} x{rd},x{rs1},{iimm}'
    if op == 0x03 and f3 == 2: return f'lw x{rd},{iimm}(x{rs1})'
    if op == 0x23 and f3 == 2: return f'sw x{rs2},{sx((f7 << 5) | rd, 12)}(x{rs1})'
    if op == 0x63 and f3 == 0:
        imm = sx((w >> 31 & 1) << 12 | (w >> 7 & 1) << 11 | (w >> 25 & 0x3f) << 5 | (w >> 8 & 0xf) << 1, 13)
        return f'beq x{rs1},x{rs2},{imm:+d}'
    if op == 0x6f:
        imm = sx((w >> 31 & 1) << 20 | (w >> 12 & 0xff) << 12 | (w >> 20 & 1) << 11 | (w >> 21 & 0x3ff) << 1, 21)
        return f'jal x{rd},{imm:+d}'
    if op == 0x67: return f'jalr x{rd},{iimm}(x{rs1})'
    return f'{w:08x}'

if __name__ == '__main__':
    if len(sys.argv) > 1:   # autoprueba: python3 rvdis.py test
        assert dis(0x00a00093) == 'addi x1,x0,10'
        assert dis(0x40418333) == 'sub x6,x3,x4'
        assert dis(0x0000a583) == 'lw x11,0(x1)'
        assert dis(0x0050a023) == 'sw x5,0(x1)'
        assert dis(0xfe2c8ae3) == 'beq x25,x2,-12'
        assert dis(0x0000006f) == 'jal x0,+0'
        print('ok'); sys.exit()
    for line in sys.stdin:
        s = line.strip()
        try: out = dis(int(s, 16))
        except ValueError: out = s          # x / z
        sys.stdout.write(out + '\n'); sys.stdout.flush()
