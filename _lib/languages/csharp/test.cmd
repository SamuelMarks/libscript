@echo off
dotnet --version
dotnet new console -n hw_test
dotnet run --project hw_test
rmdir /S /Q hw_test
