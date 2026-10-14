@echo off
rem Abre el planeta en primera persona (prueba del port nativo).
rem Uso: jugar.bat [semilla] [bioma] [tamano 1-3]     ej: jugar.bat 1234 BIAutumn 1
rem Biomas: BIAutumn BIMoon BIMars BIWinterPeaks BIAcidForest BIShed BIDeadCity BITest
rem Requiere haber compilado antes con: haxe port\render.hxml  (ver docs del port)
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
