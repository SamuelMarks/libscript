# ## Overview
# Displays the installation logs or current system logs.
#
# ## Usage
# .\trigger_logs.ps1

$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive -RunLevel Highest
$aRun = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start cmd.exe /k C:\libscript\libscript.cmd logs openedx"
Register-ScheduledTask -TaskName "RunCLI" -Action $aRun -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "RunCLI"
