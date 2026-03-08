@echo off
where cargo >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  cargo --version || echo cargo found
) else (
  echo cargo skipped (not found)
)
exit /b 0
