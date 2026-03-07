@echo off
where mix >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  mix --version || echo mix found
) else (
  echo mix skipped (not found)
)
exit /b 0
