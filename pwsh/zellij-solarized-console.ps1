# Set the current zellij pane's ConPTY 16-color table to Solarized Light.

$script:ZellijSolarizedCs = @'
using System;
using System.Runtime.InteropServices;
public static class SolarizedConsole {
    [StructLayout(LayoutKind.Sequential)] public struct COORD { public short X; public short Y; }
    [StructLayout(LayoutKind.Sequential)] public struct SMALL_RECT { public short Left; public short Top; public short Right; public short Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct CONSOLE_SCREEN_BUFFER_INFOEX {
        public uint cbSize; public COORD dwSize; public COORD dwCursorPosition; public ushort wAttributes;
        public SMALL_RECT srWindow; public COORD dwMaximumWindowSize; public ushort wPopupAttributes;
        public int bFullscreenSupported;
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 16)] public uint[] ColorTable;
    }
    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)] static extern IntPtr CreateFile(string name, uint access, uint share, IntPtr sa, uint disp, uint flags, IntPtr tmpl);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool GetConsoleScreenBufferInfoEx(IntPtr h, ref CONSOLE_SCREEN_BUFFER_INFOEX info);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool SetConsoleScreenBufferInfoEx(IntPtr h, ref CONSOLE_SCREEN_BUFFER_INFOEX info);
    [DllImport("kernel32.dll", SetLastError = true)] static extern bool CloseHandle(IntPtr h);
    public static bool Apply() {
        IntPtr h = CreateFile("CONOUT$", 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero);
        if (h.ToInt64() == -1) return false;
        try {
            var info = new CONSOLE_SCREEN_BUFFER_INFOEX();
            info.cbSize = (uint)Marshal.SizeOf(typeof(CONSOLE_SCREEN_BUFFER_INFOEX));
            info.ColorTable = new uint[16];
            if (!GetConsoleScreenBufferInfoEx(h, ref info)) return false;
            info.ColorTable[0]  = 0x00E3F6FD;
            info.ColorTable[1]  = 0x002F32DC;
            info.ColorTable[2]  = 0x00009985;
            info.ColorTable[3]  = 0x000089B5;
            info.ColorTable[4]  = 0x00D28B26;
            info.ColorTable[5]  = 0x008236D3;
            info.ColorTable[6]  = 0x0098A12A;
            info.ColorTable[7]  = 0x00837B65;
            info.ColorTable[8]  = 0x00364207;
            info.ColorTable[9]  = 0x00164BCB;
            info.ColorTable[10] = 0x00756E58;
            info.ColorTable[11] = 0x00837B65;
            info.ColorTable[12] = 0x00969483;
            info.ColorTable[13] = 0x00C4716C;
            info.ColorTable[14] = 0x00A1A193;
            info.ColorTable[15] = 0x00E3F6FD;
            info.wAttributes = 0x00F7;
            return SetConsoleScreenBufferInfoEx(h, ref info);
        } finally { CloseHandle(h); }
    }
}
'@

try {
    $dll = Join-Path $env:TEMP 'SolarizedLightConsole.dll'
    if (Test-Path -LiteralPath $dll) {
        Add-Type -Path $dll
    }
    else {
        Add-Type -TypeDefinition $script:ZellijSolarizedCs -OutputAssembly $dll
    }
    [SolarizedConsole]::Apply() | Out-Null
}
catch {
    # Console color adaptation is optional; the profile itself remains usable.
}
