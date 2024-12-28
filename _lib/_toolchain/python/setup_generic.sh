#!/bin/sh

realpath -- "${0}"
set -xv
guard='H_'"$(realpath -- "${0}" | sed 's/[^a-zA-Z0-9_]/_/g')"
if env | grep -qF "${guard}"; then return ; fi
export "${guard}"=1
curl -LsSf https://astral.sh/uv/install.sh | sh

uv python install "${PYTHON_VERSION}"
