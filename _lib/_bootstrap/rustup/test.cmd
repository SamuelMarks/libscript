@echo off
set "PATH=%USERPROFILE%\.cargo\bin;%PATH%"
where rustup >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  rustup --version || echo rustup found
) else (
  echo rustup skipped (not found)
)
exit /b 0
