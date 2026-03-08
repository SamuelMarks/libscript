@echo off
where spack >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  spack --version || echo spack found
) else (
  echo spack skipped (not found)
)
exit /b 0
