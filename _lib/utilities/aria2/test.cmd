@echo off
where aria2 >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  aria2 --version || echo aria2 found
) else (
  echo aria2 skipped (not found)
)
exit /b 0
