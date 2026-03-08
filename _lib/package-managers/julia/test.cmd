@echo off
where julia >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  julia --version || echo julia found
) else (
  echo julia skipped (not found)
)
exit /b 0
