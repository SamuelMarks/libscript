@echo off
where sbt >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  sbt --version || echo sbt found
) else (
  echo sbt skipped (not found)
)
exit /b 0
