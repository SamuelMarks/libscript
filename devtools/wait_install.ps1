# ## Overview
# Waits for the installation process to complete.
#
# ## Usage
# .\wait_install.ps1

while ((Get-ScheduledTask -TaskName "RunCLI" -ErrorAction SilentlyContinue).State -eq "Running") { Start-Sleep -Seconds 10 }
