# IIS Web Server Module

This module enables and configures Microsoft Internet Information Services (IIS) on Windows.

## Supported Platforms

- Windows

## Overview

Uses `Enable-WindowsOptionalFeature` (or equivalent DISM/ServerManager commands) to install the core IIS Web Server role, including HTTP features and FastCGI module for PHP support.
