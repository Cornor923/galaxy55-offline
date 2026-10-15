@echo off
rem Galaxy 55 (offline) - port nativo. Abre el menu de inicio.
rem Requiere compilar antes con:  haxe port\game.hxml   (ver port\LEEME.md)
rem Busca "hl" en: la variable HL, el PATH, o una carpeta tools-portable junto al repositorio.
if defined HL set PATH=%HL%;%PATH%
cd /d "%~dp0.."
where hl >nul 2>nul
if errorlevel 1 (
  for /d %%D in ("..\tools-portable\hashlink\*") do set PATH=%%~fD;%PATH%
)
where hl >nul 2>nul
if errorlevel 1 (
  echo No encuentro hl.exe. Pon HashLink en el PATH o define la variable HL con su carpeta.
  pause
  exit /b 1
)
if not exist port\out\galaxy55.hl (
  echo Falta port\out\galaxy55.hl: compila primero con  haxe port\game.hxml
  pause
  exit /b 1
)
hl port\out\galaxy55.hl %*
