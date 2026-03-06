# IIS Web Server Module

## Purpose

This document provides context and technical details for the `iis` component (part of `_server`) within the LibScript ecosystem. This module enables and configures Microsoft Internet Information Services (IIS) on Windows platforms.

## Overview

Uses `Enable-WindowsOptionalFeature` (or equivalent DISM/ServerManager commands) to install the core IIS Web Server role, including HTTP features and FastCGI module for PHP support.

This component works both as a local version manager (similar to rvm, nvm, pyenv, uv) and can be invoked from the global version manager `libscript`. 

Furthermore, IIS can be used by libscript to build bigger stacks (like WordPress, Open edX, Nextcloud, etc.) natively on Windows servers.

### Usage with LibScript

You can easily manage the lifecycle of IIS using `libscript`. The following commands demonstrate how to install, uninstall, start, stop, and package this component:

**Install**:
```cmd
libscript.cmd install iis
```

**Uninstall**:
```cmd
libscript.cmd uninstall iis
```

**Start/Stop**:
```cmd
libscript.cmd start iis
libscript.cmd stop iis
```

**Package**:
```cmd
libscript.cmd package_as msi iis
```

*Note: Since IIS is a Windows feature, usage examples reflect the Windows `libscript.cmd` CLI.*

## Supported Platforms

- Windows
