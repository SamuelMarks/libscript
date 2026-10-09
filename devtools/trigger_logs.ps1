# ## Overview
# Displays the installation logs or current system logs.
#
# ## Usage
# .\trigger_logs.ps1

$aRun = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start cmd.exe /k C:\libscript\libscript.cmd logs openedx"
Set-ScheduledTask -TaskName "RunCLI" -Action $aRun | Out-Null
Start-ScheduledTask -TaskName "RunCLI"
