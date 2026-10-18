# ## Overview
# Displays the current status of the installed services.
#
# ## Usage
# .\trigger_status.ps1

$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive -RunLevel Highest
$aRun = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start cmd.exe /k C:\libscript\libscript.cmd status openedx"
Register-ScheduledTask -TaskName "RunCLI" -Action $aRun -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "RunCLI"
