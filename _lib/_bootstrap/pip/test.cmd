@echo off
where pip >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pip --version || echo pip found
) else (
  echo pip skipped (not found)
)
exit /b 0
