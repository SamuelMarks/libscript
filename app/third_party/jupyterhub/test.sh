#!/bin/sh
set -feu
. ./env.sh
"${JUPYTERHUB_VENV}/bin/jupyterhub" --version
