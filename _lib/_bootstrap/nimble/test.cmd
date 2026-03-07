@echo off
where nimble >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  nimble --version || echo nimble found
) else (
  echo nimble skipped (not found)
)
exit /b 0
