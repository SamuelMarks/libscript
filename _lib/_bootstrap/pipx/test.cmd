@echo off
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
where pipx >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pipx --version || echo pipx found
) else (
  echo pipx skipped (not found)
)
exit /b 0
