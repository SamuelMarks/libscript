@echo off
where openrc >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  openrc --version || echo openrc found
) else (
  echo openrc skipped (not found)
)
exit /b 0
