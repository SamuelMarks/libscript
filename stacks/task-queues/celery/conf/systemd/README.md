# Celery Systemd Configuration (`stacks/task-queues/celery/conf/systemd`)

## Overview

This directory contains template unit configuration files for running Celery worker and beat daemons
under systemd on Linux.

## Purpose

Provides declarative process supervision, concurrency controls, log directory configuration, and
runtime environment paths for Celery task worker instances.

## Usage

Applied during service installation:

```sh
./stacks/task-queues/celery/setup.sh install-service
```
