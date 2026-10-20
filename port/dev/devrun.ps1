param([string]$Script, [int]$Timeout = 120, [string]$Extra = "", [string]$Data = "")
# Uso: powershell -File port/dev/devrun.ps1 -Script port/dev/synth.txt   (ver Dev.hx para las ordenes). Necesita haber compilado port/game.hxml.
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
Set-Location $repo
# con Haxe/HashLink portables junto al repositorio (si existen); si no, hl debe estar en el PATH
$env1 = "$repo\..\tools-portable\env.ps1"
if (Test-Path $env1) { . $env1 }
$env:GALAXY55_DATA = if ($Data) { $Data } else { "$repo\port\out\testdata" }
# como jugar.bat: galaxy55.exe (hl.exe con el icono del juego, port\tools\galaxy55_exe.ps1), asi la ventana de prueba lleva
# el icono y Discord no la toma por Half-Life. Se crea la primera vez; si no se puede, hl
$exe = "$repo\port\out\galaxy55.exe"
$hl = Get-Command hl -ErrorAction SilentlyContinue
if (-not (Test-Path $exe) -and $hl) { try { & "$repo\port\tools\galaxy55_exe.ps1" -Hl $hl.Source -Out $exe | Out-Null } catch {} }
$run = if (Test-Path $exe) { $exe } else { "hl" }
$p = Start-Process $run -ArgumentList "port/out/galaxy55.hl --script=$Script $Extra" -PassThru -RedirectStandardOutput "$repo\port\out\dev_out.txt" -RedirectStandardError "$repo\port\out\dev_err.txt" -WindowStyle Minimized
if (-not $p.WaitForExit($Timeout * 1000)) { Stop-Process $p -Force; "TIMEOUT" }
Get-Content "$repo\port\out\dev_out.txt" | Where-Object { $_ -notmatch '^(fondo|ruta|mundo)' }
$e = Get-Content "$repo\port\out\dev_err.txt" -ErrorAction SilentlyContinue | Select-Object -First 8
if ($e) { "ERR: $e" }
