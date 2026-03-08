@echo off
where uv >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  uv --version || echo uv found
) else (
  echo uv skipped (not found)
)
exit /b 0
