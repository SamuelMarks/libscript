@echo off
where maven >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  maven --version || echo maven found
) else (
  echo maven skipped (not found)
)
exit /b 0
