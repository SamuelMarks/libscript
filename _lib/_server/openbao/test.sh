#!/bin/sh
set -e
if command -v bao >/dev/null 2>&1; then bao version; echo hello from bao; else echo skipped; fi
