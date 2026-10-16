param([string]$Out, [string]$List, [int]$Cols = 2, [int]$W = 640)
# Junta varias capturas de port/out en una hoja (para revisar animaciones). Uso: sheet.ps1 -Out hoja -List a,b,c
Add-Type -AssemblyName System.Drawing
$Names = $List.Split(",")
$dir = (Resolve-Path "$PSScriptRoot\..\out").Path
$first = [Drawing.Image]::FromFile("$dir\$($Names[0]).png")
$H = [int]($W * $first.Height / $first.Width); $first.Dispose()
$rows = [math]::Ceiling($Names.Count / $Cols)
$bmp = New-Object Drawing.Bitmap ($W * $Cols), ($H * $rows)
$g = [Drawing.Graphics]::FromImage($bmp)
$g.InterpolationMode = 'HighQualityBicubic'
$font = New-Object Drawing.Font 'Arial', 14
for ($k = 0; $k -lt $Names.Count; $k++) {
	$i = [Drawing.Image]::FromFile("$dir\$($Names[$k]).png")
	$x = ($k % $Cols) * $W; $y = [math]::Floor($k / $Cols) * $H
	$g.DrawImage($i, $x, $y, $W, $H); $i.Dispose()
	$g.DrawString($Names[$k], $font, [Drawing.Brushes]::Yellow, $x + 4, $y + 4)
}
$bmp.Save("$dir\$Out.png")
