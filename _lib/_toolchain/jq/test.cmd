@echo off
jq --version
echo {"message": "Hello World"} | jq ".message"
