@echo off
where cpanm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  cpanm --version || echo cpanm found
) else (
  echo cpanm skipped (not found)
)
exit /b 0
