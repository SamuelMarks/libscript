#!/bin/sh

realpath -- "${0}"
set -xv
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"; then return ; fi
export "${guard}"=1

export RUST_INSTALL=0
export NODEJS_INSTALL=0
export PYTHON_INSTALL=0
export POSTGRESQL_INSTALL=0
export VALKEY_INSTALL=0
export NGINX_INSTALL=0
export CELERY_INSTALL=0
export WWWROOT_INSTALL=0
export JUPYTER_NOTEBOOK_INSTALL=0
