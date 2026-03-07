@echo off
where nvm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  nvm version || echo nvm found
) else (
  echo nvm skipped (not found)
)
exit /b 0
