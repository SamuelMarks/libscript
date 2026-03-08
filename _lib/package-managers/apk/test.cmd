@echo off
where apk >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  apk --version || echo apk found
) else (
  echo apk skipped (not found)
)
exit /b 0
