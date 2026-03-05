#!/bin/sh
set -feu
valkey-server -v || valkey-server --version || redis-server -v || redis-server --version
