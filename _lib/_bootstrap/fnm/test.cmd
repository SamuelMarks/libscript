@echo off
where fnm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  fnm --version || echo fnm found
) else (
  echo fnm skipped (not found)
)
exit /b 0
