#!/usr/bin/env python3
"""Mechanical Haxe 2 -> Haxe 3 source fixes on the build copy."""
import re, sys, glob, os

ROOT = sys.argv[1]


def split_args(s):
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return out


def fix_callbacks(src):
    n = 0
    while True:
        m = re.search(r'(?<![\w.])callback\(', src)
        if not m:
            return src, n
        i = m.end()
        depth, j = 1, i
        while depth:
            c = src[j]
            if c in "([{":
                depth += 1
            elif c in ")]}":
                depth -= 1
            j += 1
        inner = src[i:j - 1]
        args = split_args(inner)
        f = args[0].strip()
        rest = ",".join(args[1:]).strip()
        src = src[:m.start()] + "%s.bind(%s)" % (f, rest) + src[j:]
        n += 1


def fix_inherit(src):
    # class A extends B, implements C, D  ->  class A extends B implements C implements D
    def repl(m):
        head = m.group(0)
        head = re.sub(r'\s*,\s*implements\b', ' implements', head)
        head = re.sub(r'\s*,\s*extends\b', ' extends', head)
        # implements A, B  -> implements A implements B   (only inside the class/interface header)
        parts = re.split(r'(\bimplements\b)', head)
        return head
    lines = src.split("\n")
    for k, ln in enumerate(lines):
        if re.match(r'\s*(@:\w+(\([^)]*\))?\s+)*(extern\s+)?(class|interface)\s', ln) and ("extends" in ln or "implements" in ln):
            ln2 = re.sub(r'\s*,\s*implements\b', ' implements', ln)
            ln2 = re.sub(r'\s*,\s*extends\b', ' extends', ln2)
            lines[k] = ln2
    return "\n".join(lines)


total_cb = 0
for f in glob.glob(ROOT + "/**/*.hx", recursive=True):
    s = open(f, encoding="utf8", errors="surrogateescape").read()
    o = s
    s, n = fix_callbacks(s)
    s = fix_inherit(s)
    total_cb += n
    if s != o:
        open(f, "w", encoding="utf8", errors="surrogateescape").write(s)
print("callbacks reescritos:", total_cb)
