@echo off
where brew >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  brew --version || echo brew found
) else (
  echo brew skipped (not found)
)
exit /b 0
