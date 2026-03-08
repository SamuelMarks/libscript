@echo off
where npm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  npm --version || echo npm found
) else (
  echo npm skipped (not found)
)
exit /b 0
