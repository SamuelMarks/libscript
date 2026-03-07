@echo off
where pkgx >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pkgx --version || echo pkgx found
) else (
  echo pkgx skipped (not found)
)
exit /b 0
