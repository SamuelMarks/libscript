@echo off
go version
echo package main > hw.go
echo import "fmt" >> hw.go
echo func main() { fmt.Println("Hello World") } >> hw.go
go run hw.go
del hw.go
