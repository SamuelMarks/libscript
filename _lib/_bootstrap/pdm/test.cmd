@echo off
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
where pdm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pdm --version || echo pdm found
) else (
  echo pdm skipped (not found)
)
exit /b 0
