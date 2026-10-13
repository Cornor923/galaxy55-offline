import re, sys, subprocess, os, collections
env = dict(os.environ, HAXE_STD_PATH="/home/claude/haxe347/std")
for rnd in range(15):
    p = subprocess.run(["/home/claude/haxe347/haxe", "client.hxml"], capture_output=True, text=True, env=env, cwd="/home/claude/build")
    errs = re.findall(r'^(.+?\.hx):(\d+): characters (\d+)-(\d+) : Missing ;', p.stderr, re.M)
    if not errs:
        print("ronda", rnd, "sin 'Missing ;'. Salida restante:"); print(p.stderr[:3000]); break
    fixes = collections.defaultdict(list)
    for f, ln, a, b in errs: fixes[f].append((int(ln), int(b)))
    for f, lst in fixes.items():
        lines = open(f, encoding="utf8", errors="surrogateescape").read().split("\n")
        for ln, col in sorted(set(lst), reverse=True):
            s = lines[ln-1]
            lines[ln-1] = s[:col] + ";" + s[col:]
        open(f, "w", encoding="utf8", errors="surrogateescape").write("\n".join(lines))
    print("ronda", rnd, "corregidos", sum(len(set(v)) for v in fixes.values()), "en", len(fixes), "archivos")
