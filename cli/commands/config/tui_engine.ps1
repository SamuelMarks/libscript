<#
.SYNOPSIS
## Overview
Modular TUI engine providing Windows console prompts and PowerShell fallback dialogs.

## Usage
. ./cli/commands/config/tui_engine.ps1
#>

[CmdletBinding()]
param()

function Show-TuiMessageBox {
    param([string]$Title, [string]$Message)
    Write-Host "`n=== $Title ===`n$Message`n"
    [Console]::WriteLine("Press ENTER to continue...")
    [Console]::ReadLine() | Out-Null
}

function Show-TuiMenu {
    param([string]$Title, [string]$Prompt, [hashtable]$Options)
    Write-Host "`n=== $Title ===`n$Prompt`n"
    foreach ($key in $Options.Keys) {
        Write-Host "  [$key] $($Options[$key])"
    }
    Write-Host -NoNewline "Select option: "
    return [Console]::ReadLine()
}

function Show-TuiInput {
    param([string]$Title, [string]$Prompt, [string]$DefaultValue)
    Write-Host -NoNewline "$Prompt [$DefaultValue]: "
    $inputVal = [Console]::ReadLine()
    if ([string]::IsNullOrWhiteSpace($inputVal)) {
        return $DefaultValue
    }
    return $inputVal
}
