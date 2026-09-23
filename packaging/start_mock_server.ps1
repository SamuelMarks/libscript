# ## Overview
# Starts mock_server.ps1 as a background Windows scheduled task.
#
# ## Usage
# powershell -ExecutionPolicy Bypass -File packaging/start_mock_server.ps1

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File C:\libscript\packaging\mock_server.ps1"
Register-ScheduledTask -TaskName "MockServer" -Action $action -Force | Out-Null
Start-ScheduledTask -TaskName "MockServer"
Start-Sleep -Seconds 3

$lms = (Invoke-WebRequest -Uri "http://localhost:8000/dashboard" -UseBasicParsing).StatusCode
$studio = (Invoke-WebRequest -Uri "http://localhost:8001/home" -UseBasicParsing).StatusCode

Write-Host "LMS /dashboard status: $lms"
Write-Host "Studio /home status: $studio"
