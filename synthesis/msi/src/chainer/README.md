# Embedded MSI Chainer Engine (`synthesis/msi/src/chainer/`)

## Overview

`synthesis/msi/src/chainer/` contains the native Windows C/Rust embedded chainer invoked during WiX
/ `msi-rs` Immediate, Deferred, and Rollback CustomAction sequences. It translates Windows Installer
session properties (`INSTALL_*`, `PROP_*`, `USER_DB_*`) into deterministic `libscript.cmd` component
installations, tracks transactional progress milestones, and triggers clean rollback handlers if any
downstream service fails initialization.
