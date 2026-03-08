@echo off
where mise >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  mise --version || echo mise found
) else (
  echo mise skipped (not found)
)
exit /b 0
