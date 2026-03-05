# Why LibScript?

## Purpose
Explains the philosophy and engineering rationale driving LibScript: zero dependencies, high inspectability, idempotency, and native OS integration.

## What Makes The Philosophy Interesting?
In a world dominated by Docker and heavy configuration managers (Ansible, Chef, Terraform), LibScript takes a step back to the universal denominator: the Shell. It proves that you can have complex, declarative, cross-platform infrastructure management without installing massive runtimes or sacrificing access to the host machine.

## 1. Zero Dependencies (The Bootstrap Problem)
To use Ansible, you must first install Python. To use Docker, you must install the Docker Engine. LibScript solves the bootstrap problem natively. You can `curl` LibScript onto a completely raw, freshly formatted OS and instantly provision a highly complex server stack using only the built-in `/bin/sh` or `cmd.exe`.

## 2. Supreme Inspectability
Configuration management tools often obfuscate errors behind complex Domain Specific Languages (DSLs) or abstract Python stack traces. If a LibScript component fails, it's just a shell script. You run it with `sh -x setup.sh` and see the exact native command that failed. It empowers standard sysadmin debugging techniques.

## 3. Native OS Integration vs. Containers
Containers are incredible for application packaging, but they isolate you from the host OS. When you need deep OS integration—configuring native GUI apps, setting up VPNs, tuning network interfaces, or providing direct hardware access for a developer workstation—containers become an obstacle. LibScript provisions software directly to the host OS efficiently and safely.

## 4. Unrivaled Composability
LibScript acts as a comprehensive standard library for shell scripts. Developers no longer need to copy-paste OS detection or `apt`/`apk`/`brew` logic across repositories. You simply depend on the abstracted `pkg_mgr.sh` and gain universal compatibility.
