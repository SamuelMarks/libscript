# PowerShell implementation of privilege elevation
# Parallel to priv.sh and priv.cmd

function Require-Admin {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "Administrator privileges are required."
        Write-Host "Attempting to elevate..."
        
        $process = Start-Process -FilePath "pwsh" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -PassThru
        $process.WaitForExit()
        exit $process.ExitCode
    }
}

Export-ModuleMember -Function Require-Admin
