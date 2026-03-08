@echo off
where helm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  helm --version || echo helm found
) else (
  echo helm skipped (not found)
)
exit /b 0
