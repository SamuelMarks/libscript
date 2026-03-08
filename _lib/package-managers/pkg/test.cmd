@echo off
where pkg >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pkg --version || echo pkg found
) else (
  echo pkg skipped (not found)
)
exit /b 0
