@echo off
where apt >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  apt --version || echo apt found
) else (
  echo apt skipped (not found)
)
exit /b 0
