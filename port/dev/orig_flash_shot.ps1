# Abre un SWF del juego original con el reproductor Flash del repositorio y guarda capturas SOLO de su ventana (PrintWindow),
# sin tocar el resto de la pantalla. Pulsa "Continuar" en los avisos de error de ActionScript del reproductor de depuracion.
# Uso: powershell -File port/dev/orig_flash_shot.ps1 [-Swf src\G55\fla\explore\swf\explore.swf] [-Out port\out\orig] [-Seconds 12]
#      [-Clicks "x,y;x,y"]  clics (coordenadas de la ventana de juego) cada 2 s, con captura despues de cada uno
param([string]$Swf = "src\G55\fla\explore\swf\explore.swf", [string]$Out = "port\out\orig", [int]$Seconds = 10, [string]$Clicks = "")
$src = @"
using System; using System.Text; using System.Runtime.InteropServices; using System.Drawing;
public class OrigShot {
  public delegate bool EnumProc(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc p, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumChildWindows(IntPtr h, EnumProc p, IntPtr l);
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
  [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll")] public static extern IntPtr SendMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool PostMessage(IntPtr h, uint m, IntPtr w, IntPtr l);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
  public struct RECT { public int L,T,R,B; }
  public static int ClickButton(uint pid, string text) { int n=0; EnumWindows((h,x)=>{ uint p; GetWindowThreadProcessId(h,out p); if(p==pid){ EnumChildWindows(h,(c,y)=>{ var s=new StringBuilder(200); GetWindowText(c,s,200); if(s.ToString()==text){ SendMessage(c,0x00F5,IntPtr.Zero,IntPtr.Zero); n++; } return true; }, IntPtr.Zero); } return true; }, IntPtr.Zero); return n; }
  public static IntPtr FindClass(uint pid, string cls) { IntPtr r=IntPtr.Zero; EnumWindows((h,x)=>{ uint p; GetWindowThreadProcessId(h,out p); if(p==pid){ var s=new StringBuilder(100); GetClassName(h,s,100); if(s.ToString()==cls) r=h; } return true; }, IntPtr.Zero); return r; }
  public static void Click(IntPtr h, int x, int y) { IntPtr lp = (IntPtr)((y<<16)|(x&0xFFFF)); PostMessage(h,0x0200,IntPtr.Zero,lp); PostMessage(h,0x0201,(IntPtr)1,lp); PostMessage(h,0x0202,IntPtr.Zero,lp); }
  public static bool Shot(IntPtr h, string path) { RECT r; GetWindowRect(h,out r); int w=r.R-r.L, hh=r.B-r.T; if(w<=0||hh<=0) return false; var bmp=new Bitmap(w,hh); using(var g=Graphics.FromImage(bmp)){ IntPtr dc=g.GetHdc(); PrintWindow(h,dc,2); g.ReleaseHdc(dc);} bmp.Save(path); return true; }
}
"@
Add-Type -TypeDefinition $src -ReferencedAssemblies System.Drawing
$repo = (Resolve-Path "$PSScriptRoot\..\..").Path
$p = Start-Process "$repo\flashplayer_32_sa_debug.exe" -ArgumentList "$repo\$Swf" -PassThru
Start-Sleep 6
for ($i = 0; $i -lt $Seconds; $i++) { [void][OrigShot]::ClickButton($p.Id, "&Continuar"); Start-Sleep 1 }
$h = [OrigShot]::FindClass($p.Id, "ShockwaveFlash")
[void][OrigShot]::Shot($h, "$repo\$Out`_0.png")
$n = 1
foreach ($c in ($Clicks -split ";" | Where-Object { $_ -ne "" })) {
  $xy = $c -split ","
  [OrigShot]::Click($h, [int]$xy[0], [int]$xy[1])
  Start-Sleep 2
  [void][OrigShot]::Shot($h, "$repo\$Out`_$n.png")
  $n++
}
$p | Stop-Process -Force
"capturas: $Out`_0..$($n-1).png"
