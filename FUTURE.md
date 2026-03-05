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







GUID monotonic sequence derived from "package_name-OVERRIDEABLE_SERVICE_NAME-ARCH-VERSION"
   such that:
- 0.0.1 to 0.0.2 makes .msi understand it as an upgrade.
- 0.0.1 to 1.2.4 is derivable without precomputing any of the GUIDs ahead of time
```jq
# Turn a hex string (32+ chars) into an RFC4122-ish GUID
def hex_to_guid:
  .[0:8] + "-" +
  .[8:12] + "-" +
  .[12:16] + "-" +
  .[16:20] + "-" +
  .[20:32];

# Force RFC4122 version 5 + variant bits into a 32+ char hex string
def as_uuidv5_bits:
  # version (char 12, 0-based) -> '5'
  .[0:12] + "5" + .[13:] |
  # variant (char 16) -> 8..b; we’ll just force 'a'
  .[0:16] + "a" + .[17:];

# Deterministic GUID from a string (UUIDv5-like)
def guid_from_string:
  @sha256
  | .[0:32]
  | as_uuidv5_bits
  | hex_to_guid;

# Main function:
# input: "package_name-OVERRIDEABLE_SERVICE_NAME-ARCH-VERSION"
def wix_codes:
  split("-") as [$pkg,$svc,$arch,$ver] |

  # Identity for UpgradeCode (no version)
  ($pkg + "|" + $svc + "|" + $arch) as $identity |

  # Identity for ProductCode (includes version)
  ($identity + "|" + $ver) as $identity_ver |

  {
    UpgradeCode: ($identity     | guid_from_string),
    ProductCode: ($identity_ver | guid_from_string)
  };
```
