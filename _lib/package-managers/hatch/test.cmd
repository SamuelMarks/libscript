@echo off
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
where hatch >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  hatch --version || echo hatch found
) else (
  echo hatch skipped (not found)
)
exit /b 0
