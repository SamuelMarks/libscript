@echo off
setlocal
if "%~1"=="--help" (
    echo Usage: %~nx0
    echo See README.md for details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo See README.md for details.
    exit /b 0
)


set "CLUSTER_NAME=%XPK_CLUSTER_NAME%"
if "%CLUSTER_NAME%"=="" set "CLUSTER_NAME=ml-xpk-cluster"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified.
    exit /b 1
)

echo Setting up XPK Production Cluster Stack...

call gcloud auth print-access-token >nul 2>&1
if %errorlevel% neq 0 call gcloud auth login

echo Creating GKE cluster %CLUSTER_NAME% via xpk...
call "%~dp0\..\..\..\_lib\cloud-providers\gcp\gke-tpu-cluster\cli.cmd" create "%CLUSTER_NAME%"

echo Setup complete.
