# ## Overview
# Resilient browser launcher with graceful desktop shortcut fallback on Windows.
#
# ## Usage
#   .\packaging\launch_browser.ps1 -Url <http://...> [-ShortcutName <name>]

<#
.SYNOPSIS
Resilient browser launcher with graceful desktop shortcut fallback.

.DESCRIPTION
Attempts to locate and launch an active web browser (default HTTP handler, Edge, Chrome,
or Firefox) pointing to the specified URL. If no browser is installed or registered on
the system, gracefully creates a desktop .url Internet Shortcut instead of triggering
Windows "Application not found" modal errors.

.PARAMETER Url
The web address to open (e.g. http://localhost:8000).

.PARAMETER ShortcutName
Optional name for the fallback desktop shortcut (e.g. "Open edX LMS").
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Url,

    [Parameter(Position = 1)]
    [string]$ShortcutName = 'Open edX Portal'
)

$ErrorActionPreference = 'SilentlyContinue'

# 1. Search for registered HTTP handler
$browserExe = $null
try {
    $regCmd = (Get-ItemProperty -Path 'Registry::HKEY_CLASSES_ROOT\http\shell\open\command' -ErrorAction SilentlyContinue).'(default)'
    if ($regCmd) {
        $cleanPath = $regCmd -replace '^"([^"]+)".*$', '$1'
        if (Test-Path $cleanPath -PathType Leaf) {
            $browserExe = $cleanPath
        }
    }
} catch {}

# 2. Search common browser install paths
if (-not $browserExe) {
    $candidates = @(
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:ProgramFiles\Mozilla Firefox\firefox.exe",
        "${env:ProgramFiles(x86)}\Mozilla Firefox\firefox.exe",
        "$env:SystemRoot\System32\mshta.exe"
    )
    foreach ($cand in $candidates) {
        if ($cand -and (Test-Path -LiteralPath $cand -PathType Leaf)) {
            $browserExe = $cand
            break
        }
    }
}

# 3. Launch browser if available
if ($browserExe) {
    Write-Host "[INFO] Launching browser ($browserExe) for: $Url"
    try {
        [void](Start-Process -FilePath $browserExe -ArgumentList $Url -WindowStyle Normal)
        exit 0
    } catch {}
}

# 4. Fallback: Create Internet Shortcut on Public and User Desktop
Write-Host "[WARN] No web browser registered. Creating desktop Internet Shortcut for: $Url"

$desktopPaths = @(
    "$env:PUBLIC\Desktop",
    "$env:USERPROFILE\Desktop"
)

$shortcutContent = @"
[InternetShortcut]
URL=$Url
IconIndex=0
"@

foreach ($dp in $desktopPaths) {
    if ($dp -and (Test-Path $dp)) {
        $scPath = Join-Path $dp "$ShortcutName.url"
        Set-Content -Path $scPath -Value $shortcutContent -Encoding ascii -Force
        Write-Host "[INFO] Created desktop shortcut: $scPath"
    }
}

exit 0
