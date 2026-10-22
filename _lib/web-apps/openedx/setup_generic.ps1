# ## Overview
# Generic setup and provisioning module for the Open edX platform stack on Windows (PowerShell).
# Delegates lifecycle actions (install, start, stop, restart, status, test, uninstall) to setup_generic.cmd.
#
# ## Usage
# powershell -File _lib/web-apps/openedx/setup_generic.ps1 [ACTION] [OPTIONS]

param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArgs
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CmdScript = Join-Path $ScriptDir "setup_generic.cmd"

# ## Invoke-SetupGenericCmd
# Executes the canonical setup_generic.cmd batch workflow with forwarded arguments.
function Invoke-SetupGenericCmd {
    if (-not (Test-Path $CmdScript)) {
        Write-Error "[ERROR] setup_generic.cmd not found at $CmdScript"
        exit 1
    }
    $argStr = ""
    if ($RemainingArgs -and $RemainingArgs.Count -gt 0) {
        $argStr = ($RemainingArgs | ForEach-Object { "`"$_`"" }) -join " "
    } elseif ($env:ACTION) {
        $argStr = $env:ACTION
    } else {
        $argStr = "install"
    }
    & cmd.exe /c "`"$CmdScript`" $argStr"
    exit $LASTEXITCODE
}

Invoke-SetupGenericCmd
