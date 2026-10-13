#!/usr/bin/env python3
"""Genera com/NamesGen.hx con los nombres oficiales (en/es) descifrados de client_en.swf / client_es.swf."""
import json
def hx(s):
    return '"' + s.replace('\\','\\\\').replace('"','\\"').replace('\n','\\n') + '"'
out = 'class NamesGen {\n'
for lang in ('en', 'es'):
    a = json.load(open('/home/claude/orig/names_%s.json' % lang))
    items = []
    for v in a:
        if v is None or v == '0': items.append('{ name : null }')
        else: items.append('{ name : %s }' % hx(v))
    out += '\tpublic static var %s : Array<Names.NameData> = [\n\t\t%s\n\t];\n' % (lang.upper(), ',\n\t\t'.join(items))
out += '}\n'
open('/home/claude/build/G55/com/NamesGen.hx', 'w', encoding='utf8').write(out)
print('ok')
