@echo off
where cargo-binstall >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  cargo-binstall --version || echo cargo-binstall found
) else (
  echo cargo-binstall skipped (not found)
)
exit /b 0
