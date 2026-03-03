#!/bin/sh
set -feu
swift --version
cat << "SRC" > hw.swift
print("Hello World")
SRC
swift hw.swift
rm -f hw.swift
