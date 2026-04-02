#!/bin/sh
if [ -n "${INSTALLED_DIR:-}" ]; then
  if [ -d "${INSTALLED_DIR}" ]; then
    echo "Removing ${INSTALLED_DIR}..."
    rm -rf "${INSTALLED_DIR}"
    echo "No local installation directory found for redis at ${INSTALLED_DIR}."
  echo "Uninstalling redis is not supported via this script (or INSTALLED_DIR not set)."
