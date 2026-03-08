@echo off
set "PATH=%USERPROFILE%\.local\bin;%PATH%"
where conan >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  conan --version || echo conan found
) else (
  echo conan skipped (not found)
)
exit /b 0
