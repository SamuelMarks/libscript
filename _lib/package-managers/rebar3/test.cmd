@echo off
where rebar3 >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  rebar3 --version || echo rebar3 found
) else (
  echo rebar3 skipped (not found)
)
exit /b 0
