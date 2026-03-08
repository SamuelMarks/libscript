@echo off
where pacman >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pacman --version || echo pacman found
) else (
  echo pacman skipped (not found)
)
exit /b 0
