@echo off
where yarn >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  yarn --version || echo yarn found
) else (
  echo yarn skipped (not found)
)
exit /b 0
