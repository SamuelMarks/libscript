@echo off
where cygwin >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  cygwin --version || echo cygwin found
) else (
  echo cygwin skipped (not found)
)
exit /b 0
