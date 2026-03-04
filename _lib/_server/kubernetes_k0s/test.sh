#!/bin/sh
set -feu
sudo k0s status || { sleep 5; sudo k0s status; }
