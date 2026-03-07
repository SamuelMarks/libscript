@echo off
where pub >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pub --version || echo pub found
  exit /b 0
)

where dart >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  dart pub --version || echo dart pub found
  exit /b 0
)

echo pub skipped (not found)
exit /b 0
