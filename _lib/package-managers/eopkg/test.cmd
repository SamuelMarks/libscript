@echo off
where eopkg >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  eopkg --version || echo eopkg found
) else (
  echo eopkg skipped (not found)
)
exit /b 0
