param([string]$Script, [int]$Timeout = 120)
# Uso: powershell -File port/dev/devrun.ps1 -Script port/dev/synth.txt   (ver Dev.hx para las ordenes). Necesita haber compilado port/game.hxml.
$repo = "C:\Users\Usuario\Desktop\Claude\galaxy55-offline"
Set-Location $repo
. C:\Users\Usuario\Desktop\Claude\tools-portable\env.ps1
$env:GALAXY55_DATA = "$repo\port\out\testdata"
$p = Start-Process hl -ArgumentList "port/out/galaxy55.hl --script=$Script" -PassThru -RedirectStandardOutput "$repo\port\out\dev_out.txt" -RedirectStandardError "$repo\port\out\dev_err.txt" -WindowStyle Minimized
if (-not $p.WaitForExit($Timeout * 1000)) { Stop-Process $p -Force; "TIMEOUT" }
Get-Content "$repo\port\out\dev_out.txt" | Where-Object { $_ -notmatch '^(fondo|ruta|mundo)' }
$e = Get-Content "$repo\port\out\dev_err.txt" -ErrorAction SilentlyContinue | Select-Object -First 8
if ($e) { "ERR: $e" }
