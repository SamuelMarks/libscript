#!/bin/sh
set -feu
. ../../../env.sh
"${PYTHON_VENV}/bin/celery" --version
