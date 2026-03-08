@echo off
where macports >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  macports --version || echo macports found
) else (
  echo macports skipped (not found)
)
exit /b 0
