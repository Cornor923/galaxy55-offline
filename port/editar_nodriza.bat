@echo off
rem Edita la nave nodriza: entra desde el ordenador de tu nave, rompe y pon bloques (creativo, I = paleta).
rem Sal por el ordenador de tu nave aparcada para guardar en mothership.bin (copia en mothership.bin.orig).
call "%~dp0jugar_dx.bat" --editnodriza %*
