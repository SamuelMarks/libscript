@echo off
where wget >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  wget --version || echo wget found
) else (
  echo wget skipped (not found)
)
exit /b 0
