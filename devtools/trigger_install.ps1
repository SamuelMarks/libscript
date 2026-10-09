# ## Overview
# Triggers the Open edX installation process inside the Vagrant VM.
#
# ## Usage
# .\trigger_install.ps1

$principal = New-ScheduledTaskPrincipal -UserId "vagrant" -LogonType Interactive -RunLevel Highest
$aRun = New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c start cmd.exe /k C:\libscript\libscript.cmd install openedx"
Register-ScheduledTask -TaskName "RunCLI" -Action $aRun -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName "RunCLI"
