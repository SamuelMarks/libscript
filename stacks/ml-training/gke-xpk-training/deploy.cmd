@echo off
:: # deploy.cmd
::
:: ## Overview
:: Manages the deployment workflow for the GKE XPK machine learning training stack stack.
:: 
:: ## Usage
:: Execute this script to deploy gke-xpk-training to the target environment.

setlocal enabledelayedexpansion

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

if "%XPK_CLUSTER_NAME%"=="" set "XPK_CLUSTER_NAME=ml-xpk-cluster"
if "%WORKLOAD_NAME%"=="" set "WORKLOAD_NAME=ml-training-job"
if "%TRAIN_SCRIPT%"=="" set "TRAIN_SCRIPT=python train.py"

if "%GCP_PROJECT_ID%"=="" (
    echo [ERROR] GCP_PROJECT_ID must be explicitly specified.
    exit /b 1
)
if "%GCP_ZONE%"=="" (
    echo [ERROR] GCP_ZONE must be explicitly specified.
    exit /b 1
)

if "%DOCKER_IMAGE%"=="" (
    echo [ERROR] DOCKER_IMAGE must be specified.
    exit /b 1
)

if "%TPU_ACCELERATOR_TYPE%"=="" set "TPU_ACCELERATOR_TYPE=v4-8"

echo Deploying workload %WORKLOAD_NAME% to XPK cluster %XPK_CLUSTER_NAME%...

xpk workload create --cluster "%XPK_CLUSTER_NAME%" --workload "%WORKLOAD_NAME%" --command "%TRAIN_SCRIPT%" --tpu-type "%TPU_ACCELERATOR_TYPE%" --docker-image "%DOCKER_IMAGE%" --project "%GCP_PROJECT_ID%" --zone "%GCP_ZONE%"

echo Deploy complete.
exit /b 0

:help
echo Usage: deploy.cmd
exit /b 0