@echo off
where curl >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  curl --version || echo curl found
) else (
  echo curl skipped (not found)
)
exit /b 0
