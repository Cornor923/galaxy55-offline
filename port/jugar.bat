@echo off
rem Galaxy 55 (offline) - port nativo. Abre el menu de inicio.
rem Requiere compilar antes con:  haxe port\game.hxml
set HL=%~dp0..\..\tools-portable\hashlink\hashlink-1.16.0-win
set PATH=%HL%;%PATH%
cd /d "%~dp0.."
hl port\out\galaxy55.hl %*
