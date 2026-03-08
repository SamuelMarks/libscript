@echo off
where composer >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  composer --version || echo composer found
) else (
  echo composer skipped (not found)
)
exit /b 0
