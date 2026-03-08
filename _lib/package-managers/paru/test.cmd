@echo off
where paru >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  paru --version || echo paru found
) else (
  echo paru skipped (not found)
)
exit /b 0
