@echo off
where choco >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  choco --version || echo choco found
) else (
  echo choco skipped (not found)
)
exit /b 0
