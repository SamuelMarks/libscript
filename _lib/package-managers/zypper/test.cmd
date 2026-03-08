@echo off
where zypper >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  zypper --version || echo zypper found
) else (
  echo zypper skipped (not found)
)
exit /b 0
