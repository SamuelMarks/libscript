@echo off
where poetry >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  poetry --version || echo poetry found
) else (
  echo poetry skipped (not found)
)
exit /b 0
