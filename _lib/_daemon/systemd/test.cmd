@echo off
where systemd >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  systemd --version || echo systemd found
) else (
  echo systemd skipped (not found)
)
exit /b 0
