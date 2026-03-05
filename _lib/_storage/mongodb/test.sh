#!/bin/sh
set -e
if command -v mongod >/dev/null 2>&1; then mongod --version; echo hello from mongod; else echo skipped; fi
