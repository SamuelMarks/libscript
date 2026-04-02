# Dependency Management & Resolution

LibScript employs a sophisticated, automated dependency resolution engine to facilitate cross-platform software provisioning. This ensures that every stack component is deployed with the correct versions and configuration, regardless of the underlying operating system.

## Automated Stack Resolution Engine

The heart of LibScript's dependency management is a global resolution engine that treats a stack as a collection of versioned constraints. When a `libscript.json` file is processed:

- **Constraint Solving:** The engine parses version constraints (e.g., `postgres>=16`, `python~=3.10`) across the entire stack to find a compatible set of components.
- **Transitive Dependencies:** It automatically identifies and pulls in necessary sub-dependencies required by the requested components.
- **Conflict Resolution:** If multiple components require conflicting versions of the same dependency, the engine utilizes a built-in constraint solver to determine if a compatible version exists or flags the conflict for manual resolution.

## Cross-Platform Parity

LibScript achieves seamless cross-platform execution by maintaining strict parity between its POSIX shell and Windows CMD implementations.

- **Native Package Translation:** The system abstracts the native package managers of supported environments (`apt`, `apk`, `dnf`, `brew`, `pacman`, `pkg`, `choco`, `winget`). Generic dependencies are mapped to the appropriate local format at execution time.
- **Script Mirroring:** Every core logic path is implemented twice—once in POSIX-compliant `/bin/sh` for Unix-like systems and once in native Windows batch scripts (`.cmd`). This ensures that the dependency engine behaves identically whether it is running on a minimalist Alpine Linux container or a standard Windows 11 workstation.

## Component Interaction Models

Components within a stack (such as a database and its consumers) define their interactions via `vars.schema.json`:

- **Shared State:** Using `reuse` mode, multiple components can link to a single, existing service or database instance.
- **Isolated Instances:** The `install-alongside` mode allows for the provisioning of a private, isolated instance of a dependency for a specific component.
- **Environment Mapping:** The engine automatically maps inter-component configuration (ports, credentials, hostnames) into environment variables, ensuring consistent communication across all services in the stack.
