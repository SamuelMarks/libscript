#!/bin/sh
set -feu
valkey-cli PING || redis-cli PING
