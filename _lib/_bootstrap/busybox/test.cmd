@echo off
where busybox >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  busybox --version || echo busybox found
) else (
  echo busybox skipped (not found)
)
exit /b 0
