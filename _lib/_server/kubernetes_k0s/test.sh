#!/bin/sh
set -feu
sudo /usr/local/bin/k0s status || { sleep 5; sudo /usr/local/bin/k0s status; }
