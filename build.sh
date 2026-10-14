#!/bin/sh
# Compila las tres versiones. Necesita Haxe 3.4.7 en el PATH (y HAXE_STD_PATH si hace falta).
set -e
cd "$(dirname "$0")"
mkdir -p out
python3 tools/gen_names.py
for f in client client_en client_fr; do haxe $f.hxml; done
ls -la out
