# LibScript Custom Distribution Synthesis Pipelines

This directory provides complete, from-scratch distribution synthesis engines:

- `build_debian.sh` / `build_debian.cmd`: Multi-stage Debian-style GNU/Linux distribution
  synthesizer (`.deb`, `dpkg`, `apt`, APT archive repository).
- `build_alpine.sh` / `build_alpine.cmd`: Minimalist Musl-based Alpine Linux-style distribution
  synthesizer (`.apk`, `apk-tools`, `APKINDEX`, OpenRC).
- `build_redhat.sh` / `build_redhat.cmd`: Red Hat-inspired enterprise Linux synthesizer (`.rpm`,
  `rpmbuild`, `dnf`, `repodata`).
- `distro.sh` / `distro.cmd`: Unified CLI orchestrator for distribution builds.

## Configuration Options

The following environment variables can be passed to the CLI (`--KEY=VALUE`) or exported before
running the setup script.

<!-- BEGIN_VARS -->
<!-- END_VARS -->

## Platform Support

<!-- BEGIN_PLATFORMS -->
<!-- END_PLATFORMS -->
