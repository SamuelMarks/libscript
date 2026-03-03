@echo off
valkey-cli PING || redis-cli PING
