#!/bin/sh
set -feu
go version
cat << "SRC" > hw.go
package main
import "fmt"
func main() { fmt.Println("Hello World") }
SRC
go run hw.go
rm -f hw.go
