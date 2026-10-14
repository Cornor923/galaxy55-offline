@echo off
rem Compila las tres versiones. Necesita Haxe 3.4.7 en el PATH.
cd /d "%~dp0"
if not exist out mkdir out
python tools\gen_names.py
for %%f in (client client_en client_fr) do haxe %%f.hxml
dir out
