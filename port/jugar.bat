@echo off
rem Galaxy 55 (offline) - port nativo. Abre el menu de inicio.
rem Requiere compilar antes con:  haxe port\game.hxml   (ver port\LEEME.md)
rem Usa "hl" del PATH; si esta en otra carpeta, define la variable HL con su ruta.
if defined HL set PATH=%HL%;%PATH%
cd /d "%~dp0.."
if not exist port\out\galaxy55.hl (
  echo Falta port\out\galaxy55.hl: compila primero con  haxe port\game.hxml
  pause
  exit /b 1
)
hl port\out\galaxy55.hl %*
