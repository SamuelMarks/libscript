#!/bin/sh
set -feu
dotnet --version
dotnet new console -n hw_test
dotnet run --project hw_test
rm -rf hw_test
