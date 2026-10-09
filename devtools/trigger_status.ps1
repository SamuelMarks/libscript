# ## Overview
# Displays the current status of the installed services.
#
# ## Usage
# .\trigger_status.ps1

$aRun = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start cmd.exe /k C:\libscript\libscript.cmd status openedx"
Set-ScheduledTask -TaskName "RunCLI" -Action $aRun | Out-Null
Start-ScheduledTask -TaskName "RunCLI"
