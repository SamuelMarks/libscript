@echo off
rem ## Overview
rem Test suite for the gke-tpu-cluster component.
rem
rem ## Usage
rem Execute this script to perform a component-specific test.

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

gke-tpu-cluster --version
