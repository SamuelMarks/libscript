@echo off
where volta >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  volta --version || echo volta found
) else (
  echo volta skipped (not found)
)
exit /b 0
