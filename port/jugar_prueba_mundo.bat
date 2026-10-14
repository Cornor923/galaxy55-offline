@echo off
rem Prueba tecnica anterior: abre directamente un planeta (sin menu). Uso: jugar_prueba_mundo.bat [semilla] [bioma] [tamano 1-3]
set HL=%~dp0..\..\tools-portable\hashlink\hashlink-1.16.0-win
set PATH=%HL%;%PATH%
cd /d "%~dp0.."
set SEED=%1
if "%SEED%"=="" set SEED=1234
set BIOME=%2
if "%BIOME%"=="" set BIOME=BIAutumn
set SIZE=%3
if "%SIZE%"=="" set SIZE=1
hl port\out\render.hl %SEED% %BIOME% %SIZE%
