@echo off
where kubectl-krew >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  kubectl-krew --version || echo kubectl-krew found
) else (
  echo kubectl-krew skipped (not found)
)
exit /b 0
