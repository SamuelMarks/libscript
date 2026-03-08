@echo off
where emerge >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  emerge --version || echo emerge found
) else (
  echo emerge skipped (not found)
)
exit /b 0
