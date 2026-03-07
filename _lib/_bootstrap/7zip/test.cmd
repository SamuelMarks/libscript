@echo off
where 7zip >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  7zip --version || echo 7zip found
) else (
  echo 7zip skipped (not found)
)
exit /b 0
