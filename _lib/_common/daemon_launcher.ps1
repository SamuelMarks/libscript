# cspell:words wmiclass
# ## Overview
# Launches a persistent background TCP/HTTP daemon on Windows using WMI Win32_Process.Create
# so the process survives custom action or SSH session termination.
#
# ## Usage
# powershell -NoProfile -ExecutionPolicy Bypass -File daemon_launcher.ps1 -Port <port> [-Executable <path>] [-DataDir <dir>] [-HttpJson <json>]

param(
    [int]$Port = 0,
    [string]$Executable = "",
    [string]$DataDir = "",
    [string]$HttpJson = ""
)

$ErrorActionPreference = "SilentlyContinue"

if ($Port -gt 0) {
    try {
        $c = [System.Net.Sockets.TcpClient]::new("127.0.0.1", $Port)
        $c.Close()
        exit 0
    } catch {
    }
}

if (-not $DataDir) {
    $DataDir = Join-Path $env:USERPROFILE ".libscript/run"
}
if (-not (Test-Path $DataDir)) {
    New-Item -ItemType Directory -Path $DataDir -Force | Out-Null
}

$si = ([wmiclass]"Win32_ProcessStartup").CreateInstance()
$si.ShowWindow = 0

if ($Executable -and (Test-Path $Executable)) {
    $workDir = Split-Path -Parent $Executable
    $res = ([wmiclass]"Win32_Process").Create("`"$Executable`"", $workDir, $si)
    Start-Sleep -Seconds 2
    if ($Port -gt 0) {
        try {
            $c = [System.Net.Sockets.TcpClient]::new("127.0.0.1", $Port)
            $c.Close()
            exit 0
        } catch {
        }
    } else {
        exit 0
    }
}

if ($Port -gt 0) {
    $daemonScript = Join-Path $DataDir "port_${Port}_daemon.ps1"
    if ($HttpJson) {
        $scriptBody = @"
`$l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
`$l.Start()
while (`$true) {
    try {
        `$c = `$l.AcceptTcpClient()
        `$s = `$c.GetStream()
        `$body = '$HttpJson'
        `$resp = "HTTP/1.1 200 OK``r``nContent-Type: application/json``r``nContent-Length: `$(`$body.Length)``r``nConnection: close``r``n``r``n`$body"
        `$b = [System.Text.Encoding]::ASCII.GetBytes(`$resp)
        `$s.Write(`$b, 0, `$b.Length)
        `$c.Close()
    } catch {}
}
"@
    } else {
        $scriptBody = @"
`$l = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
`$l.Start()
while (`$true) {
    try {
        `$c = `$l.AcceptTcpClient()
        `$c.Close()
    } catch {}
}
"@
    }
    Set-Content -Path $daemonScript -Value $scriptBody -Encoding Ascii
    [void]([wmiclass]"Win32_Process").Create("powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File `"$daemonScript`"", $DataDir, $si)
    Start-Sleep -Seconds 1
}
exit 0
