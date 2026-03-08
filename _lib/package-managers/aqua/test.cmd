@echo off
where aqua >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  aqua -v || echo aqua found
) else (
  echo aqua skipped (not found)
)
exit /b 0
