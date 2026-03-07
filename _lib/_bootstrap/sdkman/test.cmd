@echo off
where sdk >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  sdk --version || echo sdk found
) else (
  echo sdk skipped (not found)
)
exit /b 0
