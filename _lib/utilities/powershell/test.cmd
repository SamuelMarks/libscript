@echo off
where powershell >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  powershell --version || echo powershell found
) else (
  echo powershell skipped (not found)
)
exit /b 0
