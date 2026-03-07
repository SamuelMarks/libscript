@echo off
where xbps >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  xbps --version || echo xbps found
) else (
  echo xbps skipped (not found)
)
exit /b 0
