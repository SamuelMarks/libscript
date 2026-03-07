@echo off
where snap >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  snap --version || echo snap found
) else (
  echo snap skipped (not found)
)
exit /b 0
