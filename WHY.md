# Why LibScript?

In a world full of configuration management tools (Ansible, Chef, Puppet) and containerization solutions (Docker, Kubernetes), why build a shell-script-based provisioning framework?

## 1. Zero Dependencies (The Bootstrap Problem)
If you want to run Ansible, you need Python installed on the target machine. If you want to run Chef, you need Ruby. LibScript solves the "bootstrap problem." It requires strictly POSIX-compliant `/bin/sh` (or `cmd.exe` on Windows). You can curl a LibScript bundle and run it on a completely bare, freshly installed operating system without installing anything else first.

## 2. Inspectability and Debuggability
When a configuration management tool fails, you often have to dig through complex DSLs (Domain Specific Languages) and abstract error traces. When a LibScript component fails, it's just a shell script. You can run it with `sh -x setup.sh` and see exactly which command failed, right down to the native package manager call.

## 3. Native OS Integration vs Containers
Docker is excellent for packaging applications, but terrible for configuring a developer's local workstation or setting up an OS-native environment where performance, direct hardware access, or deep OS integration (like GUI apps, VPNs, or system daemons) is required. LibScript targets the host OS natively.

## 4. Composability
LibScript acts as a standard library for shell scripts. Instead of copying and pasting the same 50 lines of "how to detect the OS and install curl" across every project you own, you simply depend on `_lib/_common/os_info.sh` and `pkg_mgr.sh`.

## 5. Idempotency without the Overhead
While shell scripts are typically imperative and not idempotent, LibScript enforces idempotent design patterns in its components. This brings the primary benefit of declarative systems (you can run it 10 times and the result is the same) without the massive footprint.
