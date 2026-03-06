# Usage Guide

This guide provides basic instructions for utilizing the LibScript CLI to provision software and generate artifacts.

## Native Component Installation

To install a tool natively, bypassing containerization, use the `install` subcommand:

```sh
./libscript.sh install nodejs 20
./libscript.sh install rust latest
```

## Declarative Stack Building

You can define a stack's requirements in a `libscript.json` file. The framework will resolve the necessary inter-component dependencies.

Example `libscript.json` for a basic web stack:

```json
{
  "deps": {
    "httpd": "latest",
    "mariadb": "latest",
    "php": "8.2"
  }
}
```

To provision the stack natively:

```sh
./libscript.sh apply
```

## Artifact Generation

To generate artifacts from a component or stack, utilize the `package_as` subcommand.

Generate a Dockerfile:

```sh
./libscript.sh package_as docker
```

Generate a Windows installer (requires appropriate toolchain if built on Linux):

```sh
./libscript.sh package_as msi
```

For advanced configuration options, see the specific module documentation in `_lib/DOCS.md` if available.
