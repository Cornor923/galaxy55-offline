param([Parameter(Mandatory)][string]$Hl, [Parameter(Mandatory)][string]$Out, [string]$Icon)
# galaxy55.exe: copia de hl.exe (HashLink) con el icono del juego y sin consola.
# - Con su propio nombre, Discord ya no lo toma por Half-Life (hl.exe).
# - El icono va en los recursos del exe: lo usan el Explorador y, en Windows, la ventana y la barra de tareas
#   (SDL toma el primer icono del exe para sus ventanas).
# - Subsistema 2 (ventana) en la cabecera PE, como el hlw.exe de antes: no se abre la consola negra vacia.
# Uso: powershell -File port\tools\galaxy55_exe.ps1 -Hl <ruta de hl.exe> -Out <ruta de galaxy55.exe>
$ErrorActionPreference = "Stop"
# (Windows PowerShell 5.1 no conoce $PSScriptRoot en los valores por defecto de param)
if (-not $Icon) { $Icon = Join-Path $PSScriptRoot "..\galaxy55.ico" }
$Out =$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Out)
$bytes = [IO.File]::ReadAllBytes((Resolve-Path $Hl).Path)
$pe = [BitConverter]::ToInt32($bytes, 0x3C)
if ([Text.Encoding]::ASCII.GetString($bytes, $pe, 4) -ne "PE`0`0") { throw "$Hl no es un ejecutable PE" }
$bytes[$pe + 0x5C] = 2
# se prepara en un temporal y se renombra al final: nunca queda un galaxy55.exe a medias
$tmp = "$Out.tmp"
[IO.File]::WriteAllBytes($tmp, $bytes)

# el .ico se copia tal cual: cada imagen es un RT_ICON y la cabecera un RT_GROUP_ICON que las enumera
Add-Type @'
using System;
using System.IO;
using System.Runtime.InteropServices;
public static class Galaxy55ExeIcon {
	[DllImport("kernel32", SetLastError = true, CharSet = CharSet.Unicode)] static extern IntPtr BeginUpdateResource(string file, bool deleteExisting);
	[DllImport("kernel32", SetLastError = true)] static extern bool UpdateResource(IntPtr h, IntPtr type, IntPtr name, ushort lang, byte[] data, uint size);
	[DllImport("kernel32", SetLastError = true)] static extern bool EndUpdateResource(IntPtr h, bool discard);
	const int RT_ICON = 3, RT_GROUP_ICON = 14;
	public static void Set(string exe, byte[] ico) {
		int n = BitConverter.ToUInt16(ico, 4);
		IntPtr h = BeginUpdateResource(exe, false);
		if( h == IntPtr.Zero ) throw new System.ComponentModel.Win32Exception();
		try {
			MemoryStream grp = new MemoryStream();
			BinaryWriter w = new BinaryWriter(grp);
			w.Write((ushort)0); w.Write((ushort)1); w.Write((ushort)n);
			for( int i = 0; i < n; i++ ) {
				int e = 6 + 16 * i;
				int size = BitConverter.ToInt32(ico, e + 8), offset = BitConverter.ToInt32(ico, e + 12);
				byte[] img = new byte[size];
				Array.Copy(ico, offset, img, 0, size);
				if( !UpdateResource(h, (IntPtr)RT_ICON, (IntPtr)(i + 1), 0, img, (uint)size) ) throw new System.ComponentModel.Win32Exception();
				w.Write(ico, e, 12);
				w.Write((ushort)(i + 1));
			}
			byte[] g = grp.ToArray();
			if( !UpdateResource(h, (IntPtr)RT_GROUP_ICON, (IntPtr)1, 0, g, (uint)g.Length) ) throw new System.ComponentModel.Win32Exception();
		} catch {
			EndUpdateResource(h, true);
			throw;
		}
		if( !EndUpdateResource(h, false) ) throw new System.ComponentModel.Win32Exception();
	}
}
'@
try {
	[Galaxy55ExeIcon]::Set($tmp, [IO.File]::ReadAllBytes((Resolve-Path $Icon).Path))
	Move-Item -Force $tmp $Out
} finally {
	if (Test-Path $tmp) { Remove-Item -Force $tmp }
}
"galaxy55.exe creado: $Out"
