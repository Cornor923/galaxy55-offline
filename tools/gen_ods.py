#!/usr/bin/env python3
"""Replaces Motion Twin's ods.Data macros with generated Haxe literals.
Reads data.ods (blocks/biomes/charges/craft), writes DataGen.hx, and patches Common.hx."""
import json, re, sys

DUMP, COM = sys.argv[1], sys.argv[2]
d = json.load(open(DUMP))

KINDS = {"BlockKind": "B", "BiomeKind": "BI", "ChargeKind": "C"}
ENUM_PREFIX = {
    "BlockKind": "B", "BiomeKind": "BI", "ChargeKind": "C", "BlockType": "BT",
    "BlockModel": "M", "BlockFace": "", "Where": "W", "TriggerEffect": "T",
}
# constructor signatures: name -> list of param types
CTORS = {
    "BlockFlag": ("BF", {
        "Light": ["Float", "Float"], "Model": ["BlockModel"], "Anchor": ["BlockFace"],
        "Magnet": ["BlockFace"], "Drop": ["BlockKind", "Int"], "Charge": ["ChargeKind"],
        "Alpha": ["Float"], "Size": ["Float"] * 6, "Toggle": ["BlockKind"],
        "Textures": ["Array<Int>"], "Activable": ["Where"], "Color": ["Int", "Float"],
        "Damage": ["Float"], "Transform": ["BlockKind", "Float"], "Propagate": ["BlockKind"],
        "DropChance": ["Int"], "Heal": ["Float"], "Jump": ["Float"],
        "Track": ["TriggerEffect", "Int"], "Container": ["Int"],
    }),
    "ChargeEffect": ("CE", {"CanBreak": ["BlockKind"], "Fast": ["BlockKind", "Float"]}),
    "CraftSchema": ("CS", {"Single": ["BlockKind"], "Base": ["BlockKind", "Int"], "Line": ["BlockKind", "Int"]}),
}


def rows(sheet):
    out = []
    for r in d[sheet][1:]:
        if not r or r[0].startswith("$"):
            break
        out.append(r)
    return out


def cell(r, header, name):
    i = header.index(name)
    return r[i].strip() if i < len(r) else ""


def num(s, is_float):
    s = s.replace(",", ".") if is_float else s
    return s


def scalar(t, v):
    """Literal for a single (non-array) typed value inside constructor params or cells."""
    if t in ENUM_PREFIX:
        return ENUM_PREFIX[t] + v
    if t == "Int":
        return v
    if t == "Float":
        return v if "." in v or "e" in v.lower() else v + ".0" if not v.startswith("0x") else v
    if t == "String":
        return '"' + v.replace("\\", "\\\\").replace('"', '\\"') + '"'
    raise Exception("type " + t)


def split_top(s, sep):
    """split on sep outside parentheses"""
    out, depth, cur = [], 0, ""
    for ch in s:
        if ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
        if ch == sep and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    out.append(cur)
    return out


def ctor(enum, token):
    prefix, table = CTORS[enum]
    m = re.match(r"^(\w+)(?:\((.*)\))?$", token.strip())
    name, args = m.group(1), m.group(2)
    sig = table.get(name)
    if sig is None:
        return prefix + name  # no-arg constructor
    parts = split_top(args, ",") if args is not None else []
    if sig[0] == "Array<Int>":
        return "%s%s([%s])" % (prefix, name, ",".join(parts).strip("[] "))
    lits = [scalar(t, p.strip()) for t, p in zip(sig, parts)]
    return "%s%s(%s)" % (prefix, name, ",".join(lits)) if lits else prefix + name


def field(t, raw, sep=","):
    raw = raw.strip()
    nullable = t.startswith("Null<")
    inner = t[5:-1] if nullable else t
    if inner.startswith("Array<"):
        et = inner[6:-1]
        if raw == "":
            return "[]"
        items = split_top(raw, sep)
        if et in CTORS:
            return "[" + ",".join(ctor(et, x) for x in items) + "]"
        return "[" + ",".join(scalar(et, x.strip()) for x in items) + "]"
    if raw == "":
        if nullable:
            return "null"
        raise Exception("empty non-null " + t)
    if inner in ("Float",):
        return scalar("Float", raw.replace(",", "."))
    return scalar(inner, raw)


SCHEMA = {
    "blocks": ("BlockData", [
        ("id", "BlockKind", ","), ("type", "BlockType", ","), ("texture", "Array<Int>", ","),
        ("texUp", "Array<Int>", ","), ("texDown", "Array<Int>", ","),
        ("shadeX", "Null<Float>", ","), ("shadeY", "Null<Float>", ","),
        ("shadeUp", "Null<Float>", ","), ("shadeDown", "Null<Float>", ","),
        ("power", "Null<Float>", ","), ("weight", "Null<Float>", ","),
        ("flags", "Array<BlockFlag>", "+"), ("matter", "Null<BlockKind>", ","),
        ("name", "Null<String>", ","), ("basePrice", "Null<Int>", ","),
    ]),
    "biomes": ("BiomeData", [
        ("id", "BiomeKind", ","), ("sunPower", "Float", ","), ("sunFalloff", "Null<Float>", ","),
        ("fog", "Array<Int>", ","), ("fogPower", "Float", ","), ("water", "BlockKind", ","),
        ("soils", "Array<BlockKind>", ","), ("exploreColors", "Array<Int>", ","),
        ("proba", "Int", ","), ("startThrough", "Array<BlockKind>", ","),
    ]),
    "charges": ("ChargeData", [
        ("id", "ChargeKind", ","), ("max", "Int", ","), ("effects", "Array<ChargeEffect>", "+"),
    ]),
    "craft": ("CraftRule", [
        ("id", "Int", ","), ("schema", "Array<CraftSchema>", "+"), ("out", "BlockKind", ","),
        ("count", "Null<Int>", ","),
    ]),
}


def gen_sheet(sheet):
    typ, fields = SCHEMA[sheet]
    header = d[sheet][0]
    lines = []
    for r in rows(sheet):
        items = []
        for name, t, sep in fields:
            v = cell(r, header, name) if name in header else ""
            if t in ("Float", "Int") or t in KINDS:
                pass
            if name in ("name",) and v == "":
                items.append("%s : null" % name)
                continue
            items.append("%s : %s" % (name, field(t, v, sep)))
        lines.append("\t\t{ " + ", ".join(items) + " }")
    return "\tpublic static var %s : Array<%s> = [\n%s\n\t];\n" % (sheet.upper(), typ, ",\n".join(lines))


out = "import Common;\n\nclass DataGen {\n"
for s in ("blocks", "biomes", "charges", "craft"):
    out += gen_sheet(s) + "\n"
out += "}\n"
open(COM + "/DataGen.hx", "w").write(out)

# patch Common.hx
src = open(COM + "/Common.hx").read()
if "ods.Data" not in src:
    print("Common.hx ya estaba parcheado; solo se regeneró DataGen.hx")
    sys.exit(0)
for sheet, enum_name in (("blocks", "BlockKind"), ("biomes", "BiomeKind"), ("charges", "ChargeKind")):
    prefix = KINDS[enum_name]
    ids = [r[0] for r in rows(sheet)]
    body = "\n".join("\t%s%s;" % (prefix, i) for i in ids)
    pat = re.compile(r'@:build\(ods\.Data\.build\("data\.ods",\s*"%s".*?\}\s*\)\)\s*enum %s \{\s*\}' % (sheet, enum_name), re.S)
    src, n = pat.subn("enum %s {\n%s\n}" % (enum_name, body), src)
    assert n == 1, (enum_name, n)
for sheet, typ in (("blocks", "BlockData"), ("biomes", "BiomeData"), ("charges", "ChargeData")):
    src = src.replace('ods.Data.parse("data.ods", "%s", %s)' % (sheet, typ), "DataGen.%s" % sheet.upper())
src = src.replace('ods.Data.parse("data.ods", "craft", CraftRule)', "DataGen.CRAFT")
assert "ods.Data" not in src
open(COM + "/Common.hx", "w").write(src)
print("OK:", {s: len(rows(s)) for s in SCHEMA})
