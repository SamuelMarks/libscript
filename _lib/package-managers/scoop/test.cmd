@echo off
where scoop >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  scoop --version || echo scoop found
) else (
  echo scoop skipped (not found)
)
exit /b 0
