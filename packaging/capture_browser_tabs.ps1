# ## Overview
# Automates launching Microsoft Edge with LMS and Studio tabs, toggling tab focus, and signaling screenshot capture.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/capture_browser_tabs.ps1 [-LmsUrl <url>] [-StudioUrl <url>]

<#
.SYNOPSIS
Controls Edge browser window, switches focus between LMS and Studio tabs, and triggers host capture.
#>

param(
    [string]$LmsUrl = "http://localhost:8000/login",
    [string]$StudioUrl = "http://localhost:8001/signin"
)

# Launch browser with both tabs
Start-Process "msedge.exe" -ArgumentList "--new-window", "$LmsUrl", "$StudioUrl"
Start-Sleep -Seconds 5

$wshell = New-Object -ComObject WScript.Shell
$wshell.AppActivate("Microsoft Edge")
Start-Sleep -Milliseconds 500

# Focus Tab 1: LMS
$wshell.SendKeys("^{1}")
Start-Sleep -Seconds 2

# Signal QEMU / host screendump for LMS
Set-Content -Path "C:/libscript/tab_state.txt" -Value "LMS_FOCUSED"

# Focus Tab 2: Studio CMS
$wshell.SendKeys("^{2}")
Start-Sleep -Seconds 2

# Signal QEMU / host screendump for Studio
Set-Content -Path "C:/libscript/tab_state.txt" -Value "STUDIO_FOCUSED"

exit 0
