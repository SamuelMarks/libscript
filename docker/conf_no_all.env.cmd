@echo off
:: # conf_no_all.env.cmd
::
:: ## Overview
:: Defines environment variables to disable default component installations in Docker on Windows.
::
:: ## Usage
:: Call this script to configure the environment.

set "THIS_FILE=%~f0"
set "RUST_INSTALL=0"
set "NODEJS_INSTALL=0"
set "PYTHON_INSTALL=0"
set "POSTGRESQL_INSTALL=0"
set "VALKEY_INSTALL=0"
set "MEMCACHED_INSTALL=0"
set "NGINX_INSTALL=0"
set "CELERY_INSTALL=0"
set "WWWROOT_INSTALL=0"
set "JUPYTERHUB_INSTALL=0"
