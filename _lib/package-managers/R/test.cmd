@echo off
where R >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  R --version || echo R found
) else (
  echo R skipped (not found)
)
exit /b 0
