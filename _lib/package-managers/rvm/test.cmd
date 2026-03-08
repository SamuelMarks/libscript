@echo off
where rvm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  rvm --version || echo rvm found
) else (
  echo rvm skipped (not found)
)
exit /b 0
