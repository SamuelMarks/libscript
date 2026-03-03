#!/bin/sh
set -feu
python3 --version || python --version
python3 -c "print('Hello World')" || python -c "print('Hello World')"
