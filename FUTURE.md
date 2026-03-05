# Future Architecture

## Purpose
Explores experimental paradigms and massive architectural shifts planned for LibScript.

## What Makes The Future Interesting?
LibScript aims to blur the line between local development environments, CI/CD pipelines, and production deployments. By abstracting the OS, LibScript can evolve from a package manager into a universal graph-execution engine for infrastructure.

## Upcoming Milestones
1. **Parallel Execution Graph**: 
   - Parse `libscript.json` to dynamically build a Directed Acyclic Graph (DAG) of dependencies.
   - Execute non-blocking components completely concurrently across multiple OS threads, vastly reducing bootstrap times.
2. **Vagrant Multi-Distro Testing Matrix**:
   - Orchestrate ephemeral VMs locally to run `libscript.sh test` across Alpine, FreeBSD, Debian, and AlmaLinux simultaneously, ensuring absolute shell compatibility without waiting on cloud CI runners.
3. **Compiled CLI Wrapper**:
   - Transition the global router (`libscript.sh`) into a statically compiled Rust or Go binary.
   - This binary will handle JSON parsing, DAG execution, and schema validation with extreme speed, while continuing to shell out to the underlying `.sh` and `.cmd` scripts to maintain the zero-dependency philosophy on the execution layer.
4. **State Snapshot & Rollback**:
   - Automatically back up modified configuration files to a staging directory before `setup.sh` runs.
   - If `test.sh` fails, automatically restore the state, providing transaction-like safety for OS provisioning.
