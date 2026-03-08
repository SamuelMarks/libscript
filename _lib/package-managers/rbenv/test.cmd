@echo off
where rbenv >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  rbenv --version || echo rbenv found
) else (
  echo rbenv skipped (not found)
)
exit /b 0
