@echo off
swift --version
echo print("Hello World") > hw.swift
swift hw.swift
del hw.swift
