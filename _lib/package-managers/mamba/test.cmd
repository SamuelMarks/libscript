@echo off
where micromamba >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  micromamba --version || echo mamba found
) else (
  echo mamba skipped (not found)
)
exit /b 0
