#!/bin/sh
set -feu
. ./env.sh
swift --version
cat << "SRC" > hw.swift
print("Hello World")
SRC
swift hw.swift
rm -f hw.swift
