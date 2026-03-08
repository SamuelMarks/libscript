@echo off
where yay >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  yay --version || echo yay found
) else (
  echo yay skipped (not found)
)
exit /b 0
