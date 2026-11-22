# Zero-.EXE Modular Windows Installer (.msi) Architecture

## Overview

This document specifies the architectural model for LibScript's native Windows Installer (`.msi`)
multi-package deployment system. By utilizing Windows Installer 4.5+ transactioning and the native
`MsiEmbeddedChainer` table, LibScript packages and chains complex software stacks (e.g., Open edX
Platform, WordPress) with **ZERO external `.exe` binaries** (no WiX Burn `setup.exe` bootstrappers).

---

## 1. Zero-.EXE Guarantees & Standards

Enterprise deployments require reliable, auditable, and GPO-compliant installation artifacts:

- **No Setup.exe Bootstrappers:** All master and standalone installers are pure Windows Installer
  databases (`.msi`).
- **Standard msiexec Execution:** Native silent installations operate directly via
  `msiexec /i package.msi /qn`.
- **Atomic Multi-Package Transactions:** Windows Installer coordinates all child packages under a
  single transactional unit via `MsiBeginTransaction` and `MsiEndTransaction`.
- **In-Process Custom Actions:** Actions such as database creation and port querying are handled via
  native in-process Custom Action DLLs (`Type 1`) stored directly inside the MSI's internal `Binary`
  table, eliminating command-line subprocesses.

---

## 2. Package Topology & Chaining (`MsiEmbeddedChainer`)

The installation topology consists of standalone component MSIs orchestrated by a master MSI:

```
                          ┌────────────────────────────────────┐
                          │   openedx-${VERSION}.msi (Master)  │
                          └─────────────────┬──────────────────┘
                                            │ MsiEmbeddedChainer
       ┌──────────────────┬─────────────────┼──────────────────┬──────────────────┐
       ▼                  ▼                 ▼                  ▼                  ▼
┌──────────────┐   ┌──────────────┐  ┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│libscript-    │   │libscript-    │  │libscript-    │   │libscript-    │   │openedx-      │
│mysql.msi     │   │redis.msi     │  │mongodb.msi   │   │nodejs.msi    │   │core.msi      │
└──────────────┘   └──────────────┘  └──────────────┘   └──────────────┘   └──────────────┘
```

### Chainer Table Definition in WiX:

```xml
<UI>
  <EmbeddedChainer Id="LibScriptChainer" SourceFile="binary\libscript_chainer.dll" />
</UI>
```

When `openedx.msi` executes:

1. Windows Installer initializes the `LibScriptChainer` custom action.
2. The chainer checks the system for each component's `UpgradeCode` via `MsiQueryProductState`.
3. If an existing compatible MySQL service is already detected on the system (e.g. installed
   previously by WordPress), `libscript-mysql.msi` is skipped.
4. If missing, the chainer extracts `libscript-mysql.msi` from its internal stream and passes
   properties: `msiexec /i libscript-mysql.msi PROP_PORT=3306 ...`
5. Windows Installer executes the installation within the active multi-package transaction.

---

## 3. Reference Counting & Side-by-Side Application Reuse

Multiple applications (e.g., Open edX and WordPress) can share identical database engines without
collision:

### Component Identity & KeyPath

Every shared component shares an identical `ComponentId` GUID and `KeyPath` across all packages:

- **MySQL Service Component GUID:** `{5B2783B0-9A1F-4348-9F93-87CE43C21001}`
- **KeyPath File:** `[ProgramFiles64Folder]LibScript\MySQL\bin\mysqld.exe`
- **Shared Reference Flag:** `SharedDllRefCount="yes"`

### Reference Count Lifecycle

1. **Open edX Installed:** Component `{5B2783B0-...}` ref-count set to `1`.
2. **WordPress Installed:** Windows Installer detects existing Component `{5B2783B0-...}`, links
   WordPress's `ProductCode` to the component, and increments ref-count to `2`.
3. **Open edX Uninstalled:** Windows Installer removes Open edX's database schema (`openedx`) but
   decrements ref-count to `1`. The MySQL Windows service and WordPress schema remain active.
4. **WordPress Uninstalled:** Ref-count drops to `0`. Windows Installer stops and removes the shared
   MySQL Windows service.

---

## 4. Rollback & Fault Tolerance Policy

1. **Transaction Failure:** If `openedx-core.msi` fails to deploy, the transaction rolls back
   changes made during that specific session.
2. **Pre-existing Service Protection:** Any component that was already installed prior to the
   transaction (detected via `MsiQueryProductState` with status $\ge 1$) is flagged as
   `PREEXISTING=1` and is strictly excluded from rollback removal.

---

## 5. Public Properties & Silent Parameter Forwarding

When orchestrating child MSIs silently, the master MSI forwards public properties to child packages:

| Master Property            | Child Package           | Target Property in Child | Description                              |
| :------------------------- | :---------------------- | :----------------------- | :--------------------------------------- |
| `PROP_MYSQL_PORT`          | `libscript-mysql.msi`   | `PORT`                   | Listening TCP port for MySQL             |
| `PROP_MYSQL_ROOT_PASSWORD` | `libscript-mysql.msi`   | `ROOT_PASSWORD`          | Administrative password                  |
| `PROP_REDIS_PORT`          | `libscript-redis.msi`   | `PORT`                   | Listening TCP port for Redis             |
| `PROP_MONGODB_PORT`        | `libscript-mongodb.msi` | `PORT`                   | Listening TCP port for MongoDB           |
| `INSTALL_MYSQL`            | `openedx.msi`           | `INSTALL_mysql`          | Feature toggle (1=install/reuse, 0=skip) |
