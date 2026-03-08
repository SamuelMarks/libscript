@echo off
where conda >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  conda --version || echo conda found
) else (
  echo conda skipped (not found)
)
exit /b 0
