@echo off
rem Galaxy 55 (offline) - port nativo, version DirectX (para equipos sin OpenGL 3.2, como maquinas virtuales).
rem Requiere compilar antes con:  haxe port\game_dx.hxml
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
if not exist port\out\galaxy55_dx.hl (
  echo Falta port\out\galaxy55_dx.hl: compila primero con  haxe port\game_dx.hxml
  pause
  exit /b 1
)
hl port\out\galaxy55_dx.hl %*
