# JupyterHub Systemd Configuration (`stacks/data-science/jupyterhub/conf/systemd`)

## Overview

This directory contains template unit configuration files for managing JupyterHub as a background
system service under systemd on Linux.

## Purpose

Enables automated installation and management of JupyterHub service daemons, configuring user
permissions, working directories, and process restart policies.

## Usage

Applied during generic setup or service installation:

```sh
./stacks/data-science/jupyterhub/setup.sh install-service
```
