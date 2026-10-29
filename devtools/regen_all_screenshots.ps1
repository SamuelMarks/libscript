# ## Overview
# Thin declarative caller that regenerates all .msi wizard stages and post-install
# desktop and browser verification screenshots across all components and OS platforms
# via devtools/capture_running_system.ps1 or devtools/capture_running_system.cmd.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File devtools/regen_all_screenshots.ps1 [OPTIONS]

<#
.SYNOPSIS
Regenerates packaging and browser verification screenshots from a live running system or VM.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

# ## show_help
# Displays usage instructions by delegating to capture_running_system.cmd --help.
function Show-Help {
    $cmdScript = Join-Path $ScriptDir "capture_running_system.cmd"
    & cmd.exe /c "`"$cmdScript`" --help"
    exit 0
}

# ## main
# Entrypoint delegating live screenshot capture to capture_running_system.cmd.
function Main {
    param([string[]]$ForwardArgs)

    if ($ForwardArgs -contains "--help" -or $ForwardArgs -contains "-h" -or $ForwardArgs -contains "/?" -or $ForwardArgs -contains "-?") {
        Show-Help
    }

    $cmdScript = Join-Path $ScriptDir "capture_running_system.cmd"
    if (-not (Test-Path $cmdScript)) {
        Write-Error "[ERROR] capture_running_system.cmd not found at $cmdScript"
        exit 1
    }

    $argList = @("--target", "all", "--os", "all", "--variant", "both", "--flow", "both", "--mode", "all") + $ForwardArgs
    $quotedArgs = ($argList | ForEach-Object { "`"$_`"" }) -join " "
    & cmd.exe /c "`"$cmdScript`" $quotedArgs"
    exit $LASTEXITCODE
}

Main -ForwardArgs $args
