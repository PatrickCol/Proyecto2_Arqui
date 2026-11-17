#!/usr/bin/env python3
# Waveforms del informe: simula con Icarus Verilog, abre GTKWave con las senales
# pedidas y guarda una captura PNG de la ventana (ImageMagick `import`).
# Uso: python3 -I tools/wave.py <repo EF> <figura> [<figura> ...]   (sin figuras: lista)
import os, re, subprocess, sys, tempfile, time

HERE = os.path.dirname(os.path.abspath(__file__))
IMG = os.path.join(HERE, '..', 'img')
FILTER = os.path.join(HERE, 'rvdis.py')

def simulate(repo, arch, prog, work):
    """arch: carpeta (A/B/C); prog: carpeta ProgramaN o 'profesor' (tb_proyecto)."""
    adir = os.path.join(repo, arch)
    rtl = [os.path.join(adir, f) for f in sorted(os.listdir(adir)) if f.endswith('.v') and f != 'tb_proyecto.v']
    if prog == 'profesor':
        tb = os.path.join(adir, 'tb_proyecto.v'); top = 'tb_proyecto'
    else:
        pdir = os.path.join(adir, prog)
        tb = next(os.path.join(pdir, f) for f in os.listdir(pdir) if f.startswith('tb_'))
        top = os.path.basename(tb)[:-2]
        for f in os.listdir(pdir):
            if f.endswith('.mem'): subprocess.run(['cp', os.path.join(pdir, f), work], check=True)
    subprocess.run(['cp', os.path.join(adir, 'riscvtest.dat'), work], check=True)
    open(os.path.join(work, 'dump.v'), 'w').write(
        f'module dumpvcd; initial begin $dumpfile("w.vcd"); $dumpvars(0, {top}); end endmodule\n')
    subprocess.run(['iverilog', '-g2012', '-o', 'sim', *rtl, tb, 'dump.v'], cwd=work, check=True)
    out = subprocess.run(['vvp', 'sim'], cwd=work, capture_output=True, text=True).stdout
    assert 'PASS' in out or 'SUPERADA' in out, out[-2000:]
    return top

def vcd_names(path):
    """nombre jerarquico sin rango -> nombre con rango, leyendo la cabecera del VCD."""
    names, scope = {}, []
    for line in open(path):
        t = line.split()
        if not t: continue
        if t[0] == '$scope': scope.append(t[2])
        elif t[0] == '$upscope': scope.pop()
        elif t[0] == '$var':
            base = '.'.join(scope + [t[4]])
            names.setdefault(base, base + (t[5] if len(t) > 6 and t[5].startswith('[') else ''))
        elif t[0] == '$enddefinitions': break
    return names

def shot(fig, repo):
    arch, prog, t0, t1, sigs = FIGS[fig][:5]
    height = FIGS[fig][5] if len(FIGS[fig]) > 5 else None
    work = tempfile.mkdtemp(prefix='wave_')
    top = simulate(repo, arch, prog, work)
    names = vcd_names(os.path.join(work, 'w.vcd'))
    full = [names[f"{top}.{s.split(':')[0]}"] for s in sigs]
    gtkw = os.path.join(work, 'f.gtkw')
    open(gtkw, 'w').write(f'[dumpfile] "{work}/w.vcd"\n[sst_expanded] 0\n'
                          f'[size] 1600 {height or 125 + 22 * len(sigs)}\n')
    q = lambda xs: '{' + ' '.join('{%s}' % x for x in xs) + '}'
    tcl = [f'gtkwave::addSignalsFromList {q(full)}']
    menu = {'bin': 'Binary', 'dec': 'Decimal', 'sdec': 'Signed_Decimal'}
    for name, s in zip(full, sigs):
        fmt = s.split(':')[1]
        if fmt in menu:
            tcl += ['gtkwave::/Edit/UnHighlight_All', f'gtkwave::highlightSignalsFromList {q([name])}',
                    f'gtkwave::/Edit/Data_Format/{menu[fmt]}']
    instr = [n for n, s in zip(full, sigs) if s.endswith(':instr')]
    if instr:
        tcl += [f'set p [gtkwave::setCurrentTranslateProc {FILTER}]', 'gtkwave::/Edit/UnHighlight_All',
                f'gtkwave::highlightSignalsFromList {q(instr)}', 'gtkwave::installProcFilter $p']
    tcl += ['gtkwave::/Edit/UnHighlight_All', f'gtkwave::setZoomRangeTimes {t0 * 1000} {t1 * 1000}']  # VCD en ps
    tclf = os.path.join(work, 'z.tcl'); open(tclf, 'w').write('\n'.join(tcl) + '\n')
    env = dict(os.environ, GDK_BACKEND='x11', LC_ALL='C')
    g = subprocess.Popen(['gtkwave', '-S', tclf, gtkw], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    try:
        wid = None
        for _ in range(40):
            time.sleep(0.5)
            tree = subprocess.run(['xwininfo', '-root', '-tree'], capture_output=True, text=True, env=env).stdout
            m = re.search(r'^\s+(0x[0-9a-f]+) "GTKWave - [^"]*w\.vcd[^"]*"', tree, re.M)
            if m: wid = m.group(1); break
        assert wid, 'no aparece la ventana de GTKWave'
        time.sleep(2.5)
        raw = os.path.join(work, 'raw.png')
        subprocess.run(['timeout', '20', 'import', '-window', wid, raw], check=True, env=env)
    finally:
        g.kill()
    out = os.path.join(IMG, f'{fig}.png')
    # deja solo el panel de senales y ondas (sin barra de titulo, herramientas ni scrollbar)
    h = int(subprocess.run(['identify', '-format', '%h', raw], capture_output=True, text=True).stdout)
    subprocess.run(['convert', raw, '-crop', f'1533x{h - 162 - 72}+92+162', '+repage', out], check=True)
    print(out)

A, B, C = 'Single_Issue', 'Dual_Issue', 'Dual_Issue optimizado'
P, DP, M = 'dut.rvpipeline.', 'dut.rvpipeline.dp.', 'dut.dmem.'
PAR = ['clk:bin', DP + 'InstrD0:instr', DP + 'InstrD1:instr', P + 'Issue0:bin', P + 'Issue1:bin',
       P + 'Consumed:bin', P + 'RawPair:bin', P + 'MemConflict:bin', P + 'LoadUse0:bin']
MEM_C = [DP + 'InstrM0:instr', DP + 'InstrM1:instr', M + 'we0:bin', M + 'a0:dec', M + 'wd0:dec', M + 'rd0:dec',
         M + 'we1:bin', M + 'a1:dec', M + 'wd1:dec', M + 'rd1:dec']
MEM_B = [DP + 'InstrM0:instr', DP + 'InstrM1:instr', P + 'MemSelM1:bin', M + 'we:bin', M + 'a:dec',
         M + 'wd:dec', M + 'rd:dec']
ETAPAS = ['etapa_pulso:bin', 'etapa_cerrada:bin', 'etapa_ok:bin', 'cyc_A:dec', 'cyc_B:dec', 'cyc_C:dec', 'cyc_D:dec'] + \
         [f'M_{o:02d}:dec' for o in range(0, 56, 4)] + \
         [f'sx{r}:dec' for r in (10, 18, 21, 22, 24, 28, 29, 31)]
FIN = ['clk:bin', 'cyc:dec', 'retired:dec', 'etapa_pulso:bin', 'etapa_cerrada:bin', 'etapa_ok:bin', 'cyc_D:dec'] + \
      [f'M_{o:02d}:dec' for o in (36, 40, 44, 48, 52)] + [f'sx{r}:dec' for r in (28, 29, 31)]
FIGS = {
    # nombre: (arquitectura, programa, inicio ns, fin ns, senales)
    'ef_prof_etapas_A': (A, 'profesor', 0, 4630, ETAPAS),
    'ef_prof_etapas_B': (B, 'profesor', 0, 3900, ETAPAS),
    'ef_prof_etapas_C': (C, 'profesor', 0, 3870, ETAPAS),
    'ef_prof_raw_C': (C, 'profesor', 35, 105, PAR[:7] + [DP + 'InstrE0:instr', DP + 'InstrE1:instr',
                      P + 'ForwardA0:bin', P + 'ForwardB0:bin', DP + 'SrcAE0:sdec', DP + 'SrcBE0:sdec',
                      DP + 'SrcAE1:sdec', DP + 'SrcBE1:sdec', DP + 'ResultW0:sdec', DP + 'ResultW1:sdec']),
    'ef_prof_mem_B': (B, 'profesor', 95, 245, PAR + MEM_B),
    'ef_prof_mem_C': (C, 'profesor', 95, 215, PAR + MEM_C),
    'ef_prof_fin_A': (A, 'profesor', 4571, 4607, FIN),
    'ef_prof_fin_B': (B, 'profesor', 3851, 3887, FIN),
    'ef_prof_fin_C': (C, 'profesor', 3821, 3857, FIN),
    'ef_p15_B': (B, 'Programa15_Propio', 385, 455, PAR + MEM_B),
    'ef_p15_C': (C, 'Programa15_Propio', 305, 375, PAR + MEM_C),
    'ef_p14_B': (B, 'Programa14_DoblePuerto', 40, 160, PAR + MEM_B),
    'ef_p14_C': (C, 'Programa14_DoblePuerto', 40, 125, PAR + MEM_C),
}

if __name__ == '__main__':
    if len(sys.argv) < 3: print('\n'.join(FIGS)); sys.exit()
    for f in sys.argv[2:]: shot(f, sys.argv[1])
