@echo off
rem Galaxy 55 (offline) - port nativo, Abre el menu de inicio.
rem Requiere compilar antes con:  haxe port\game.hxml
cd /d "%~dp0.."
if defined HL set "PATH=%HL%;%PATH%"
where hl >nul 2>nul
if not errorlevel 1 goto found
for /d %%D in ("..\tools-portable\hashlink\*") do set "PATH=%%~fD;%PATH%"
where hl >nul 2>nul
if not errorlevel 1 goto found
echo No encuentro hl.exe. Pon HashLink en el PATH o define la variable HL con su carpeta.
pause
exit /b 1
:found
if exist port\out\galaxy55.hl goto run
echo Falta port\out\galaxy55.hl: compila primero con  haxe port\game.hxml
pause
exit /b 1
:run
rem hlw.exe = hl.exe en modo ventana (sin la consola negra vacia), si esta junto a hl; si no, hl con su consola
where hlw >nul 2>nul && (start "" hlw port\out\galaxy55.hl %* & exit /b 0)
start "" hl port\out\galaxy55.hl %*