# Open edX Native Deployment Stack

This stack orchestrates the native deployment of Open edX (LMS and CMS) on any supported OS without
Docker. It uses `libscript` components to install and configure dependencies idempotently.

## Features

- **Cross-Platform:** Works on SunOS, Linux, macOS, FreeBSD, and Windows.
- **Idempotent:** Safe to run multiple times.
- **No Docker:** Native execution using local runtimes.
- **Complete Dependency Resolution:** Provisions Node.js, Python (with isolated virtualenvs),
  Relational and NoSQL DBs, search index, and in-memory caches.
- **Mail & Routing:** Sets up native SMTP via Exim/hmailserver and Reverse Proxies.

## Usage

**POSIX (SunOS, Linux, macOS, FreeBSD):**

```sh
./setup.sh
```

**Windows (Command Prompt):**

```cmd
setup.cmd
```
