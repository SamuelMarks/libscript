@echo off
where pnpm >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  pnpm --version || echo pnpm found
) else (
  echo pnpm skipped (not found)
)
exit /b 0
