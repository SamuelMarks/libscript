# ## Overview
# Diagnostic utility to inspect UI automation element hierarchy and button properties on Windows.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/inspect_window.ps1

<#
.SYNOPSIS
Lists open Windows Automation elements and descendant buttons.
#>

Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes

$root = [System.Windows.Automation.AutomationElement]::RootElement
$windows = $root.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
foreach ($win in $windows) {
    Write-Host "Window: '$($win.Current.Name)' Class: '$($win.Current.ClassName)'"
    $btnCond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
    $btns = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $btnCond)
    foreach ($b in $btns) {
        Write-Host "  Button: '$($b.Current.Name)' AutomationId: '$($b.Current.AutomationId)'"
    }
}
