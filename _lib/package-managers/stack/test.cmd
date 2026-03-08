@echo off
where stack >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  stack --version || echo stack found
) else (
  echo stack skipped (not found)
)
exit /b 0
