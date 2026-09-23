# LibScript Dependency Resolution & Variant Solver (`resolve_stack.jq`)
#
# Implements:
# - Input format compatibility: Accepts either traditional install.json OR os-config.json profiles
# - USE variant propagation from global profile down to component manifests
# - Tarjan's strongly connected components (SCC) algorithm for cycle detection
# - Multi-pass stage emission to safely resolve circular dependencies
# - Flat, topologically sorted execution-plan.json generation matching execution-plan.schema.json

include "semver";

def intersects(a; b):
  if a == null or b == null then false else
  [ (a[]?) as $x | (b[]?) as $y | select($x == $y) ] | length > 0
  end;

def is_os_supported(m; os):
  (m.os_blacklist // [] | index(os) == null) and
  (m.os_whitelist == null or (m.os_whitelist | length == 0) or (m.os_whitelist | index("all")) or (m.os_whitelist | index(os) != null));

# Helper for Tarjan SCC recursive step
def strongconnect(v; graph):
  .indices[v] = .index |
  .lowlinks[v] = .index |
  .index = .index + 1 |
  .stack = [v] + .stack |
  .on_stack[v] = true |
  reduce (graph[v] // [])[] as $w (
    .;
    if .indices[$w] == null then
      strongconnect($w; graph) |
      .lowlinks[v] = ([.lowlinks[v], .lowlinks[$w]] | min)
    elif .on_stack[$w] then
      .lowlinks[v] = ([.lowlinks[v], .indices[$w]] | min)
    else . end
  ) |
  if .lowlinks[v] == .indices[v] then
    (
      .stack as $st |
      ($st | index(v)) as $idx |
      ($st[0:$idx + 1]) as $scc |
      .sccs += [$scc] |
      .stack = $st[$idx + 1:] |
      reduce $scc[] as $item (.; .on_stack[$item] = false)
    )
  else . end;

# Tarjan SCC algorithm implementation
def tarjan_scc(graph):
  reduce (graph | keys)[] as $node (
    { index: 0, stack: [], indices: {}, lowlinks: {}, on_stack: {}, sccs: [] };
    if .indices[$node] == null then
      strongconnect($node; graph)
    else . end
  ) | .sccs;

# Helper for topological sort recursive step
def topo_visit(node; dag):
  if .visited[node] then .
  else
    .visited[node] = true |
    reduce (dag[node] // [])[] as $neighbor (
      .;
      topo_visit($neighbor; dag)
    ) |
    .order = [node] + .order
  end;

# Topological sort with multi-pass cycle resolution
def topological_sort(graph; cyclic_edges):
  # Remove cyclic feedback edges to form a DAG
  reduce (graph | keys)[] as $u (
    {};
    .[$u] = [ (graph[$u] // [])[] | select(($u + "->" + .) as $edge | cyclic_edges | index($edge) == null) ]
  ) as $dag |

  # Standard Kahn's algorithm or DFS post-order
  reduce ($dag | keys)[] as $node (
    { visited: {}, order: [] };
    topo_visit($node; $dag)
  ) | .order;

# Main entry point:
. as $root |
# Check if input is os-config or traditional install.json
($root.config // $root.install // $root) as $cfg |

if ($cfg.target != null and ($cfg.target.os_family != null or $cfg.target.libc != null)) then
  # ----------------------------------------------------
  # OS-CONFIG.JSON RESOLUTION MODE
  # ----------------------------------------------------
  ($cfg.target.arch // "x86_64") as $arch |
  ($cfg.target.libc // "glibc") as $libc |
  ($cfg.target.os_family // "linux-glibc") as $os_fam |
  (if ($os_fam | startswith("freebsd")) then "freebsd" elif ($os_fam | startswith("unikraft")) then "unikraft" else "linux" end) as $target_os |
  ($cfg.profile_name // "custom") as $profile |

  # Derive active global variants/USE flags from profile
  [
    (if $cfg.display?.server == "wayland" or ($cfg.display?.compositor != null and $cfg.display?.compositor != "none") then "wayland" else empty end),
    (if $cfg.display?.server == "x11" then "x11" else empty end),
    (if $cfg.init_system?.provider == "systemd" then "systemd" else empty end),
    (if $cfg.init_system?.provider == "openrc" then "openrc" else empty end),
    (if $cfg.audio?.subsystem == "pipewire" or ($cfg.desktop?.desktop_suite != null and $cfg.desktop?.desktop_suite != "none") then "pipewire" else empty end),
    (if $libc == "musl" then "musl" else "glibc" end)
  ] | unique as $global_variants |

  # Base packages to assemble
  ($cfg.packages // []) as $user_pkgs |
  ([
    (if $libc == "glibc" then "glibc" else "musl" end),
    (if $cfg.kernel?.provider then $cfg.kernel.provider else empty end),
    (if $cfg.init_system?.provider and $cfg.init_system.provider != "none" then $cfg.init_system.provider else empty end),
    (if $cfg.storage?.bootloader and $cfg.storage.bootloader != "none" then $cfg.storage.bootloader else empty end),
    (if $cfg.display?.compositor and $cfg.display.compositor != "none" then $cfg.display.compositor else empty end),
    (if $cfg.desktop?.desktop_suite and $cfg.desktop.desktop_suite != "none" then $cfg.desktop.desktop_suite else empty end),
    (if $cfg.desktop?.greeter and $cfg.desktop.greeter != "none" then $cfg.desktop.greeter else empty end)
  ] + $user_pkgs) | unique as $all_components |

  # Build dependency graph
  reduce $all_components[] as $comp (
    {};
    .[$comp] = (
      [ $root.manifests[]? | select(.name == $comp) ] |
      if length > 0 then
        (.[0].dependencies?.build_deps // []) + (.[0].dependencies?.runtime_deps // [])
      else [] end
    )
  ) as $dep_graph |

  # Identify cycles with Tarjan's SCC
  (tarjan_scc($dep_graph) | map(select(length > 1))) as $cycles |

  # Determine cyclic edges to break (pass1 vs pass2)
  [
    $cycles[] |
    . as $cycle |
    range(0; length) as $i |
    ($cycle[$i] + "->" + $cycle[($i + 1) % length])
  ] as $cyclic_edges |

  # Topologically sort packages
  (topological_sort($dep_graph; $cyclic_edges)) as $sorted_packages |

  # Emit plan structure
  {
    "plan_version": "1.0.0",
    "profile_name": $profile,
    "target": {
      "arch": $arch,
      "libc": $libc,
      "os": $target_os
    },
    "stages": [
      {
        "stage": "stage0-host-tools",
        "description": "Host-native bootstrap toolchain and cross-compiler initialization",
        "tasks": [
          {
            "name": "binutils-pass1",
            "component": "_lib/toolchains/binutils",
            "action": "bootstrap",
            "stamp": ".stamp.stage0_binutils_pass1",
            "variants": ["bootstrap"],
            "env": { "LIBSCRIPT_STAGE": "stage0" }
          },
          {
            "name": "gcc-pass1",
            "component": "_lib/toolchains/gcc",
            "action": "bootstrap",
            "stamp": ".stamp.stage0_gcc_pass1",
            "variants": ["bootstrap", "static"],
            "env": { "LIBSCRIPT_STAGE": "stage0" }
          }
        ]
      },
      {
        "stage": "stage1-cross-tools",
        "description": "Minimal cross-compiled userland for clean build isolation",
        "tasks": [
          {
            "name": "kernel-headers",
            "component": "_lib/base-system/linux-headers",
            "action": "bootstrap",
            "stamp": ".stamp.stage1_headers",
            "variants": [],
            "env": { "LIBSCRIPT_STAGE": "stage1" }
          },
          {
            "name": (if $libc == "musl" then "musl-pass1" else "glibc-pass1" end),
            "component": (if $libc == "musl" then "_lib/base-system/musl" else "_lib/base-system/glibc" end),
            "action": "bootstrap",
            "stamp": ".stamp.stage1_libc",
            "variants": ["bootstrap"],
            "env": { "LIBSCRIPT_STAGE": "stage1" }
          }
        ]
      },
      {
        "stage": "stage2-target-sysroot",
        "description": "Target rootfs compilation with active USE flags and cycle-broken dependencies",
        "tasks": [
          $sorted_packages[] |
          . as $pkg |
          ([ $root.manifests[]? | select(.name == $pkg) ][0] // {name: $pkg, category: "base-system"}) as $manifest |
          # Active variants for this package
          (
            [
              ($manifest.variants // {} | keys)[] |
              select(. as $v | $global_variants | index($v) != null)
            ]
          ) as $pkg_variants |
          {
            "name": $pkg,
            "component": ("_lib/" + ($manifest.category // "base-system") + "/" + $pkg),
            "action": "compile",
            "stamp": (".stamp." + $pkg),
            "variants": $pkg_variants,
            "env": {
              "LIBSCRIPT_STAGE": "stage2",
              "LIBSCRIPT_TARGET_ARCH": $arch,
              "LIBSCRIPT_TARGET_LIBC": $libc,
              "LIBSCRIPT_TARGET_OS": $target_os
            }
          }
        ]
      },
      {
        "stage": "stage3-media-packaging",
        "description": "Kernel injection, filesystem formatting, initramfs, and bootable image assembly",
        "tasks": [
          {
            "name": "fhs-layout",
            "component": "_lib/orchestration/fhs",
            "action": "assemble",
            "stamp": ".stamp.stage3_fhs",
            "variants": [],
            "env": { "LIBSCRIPT_STAGE": "stage3" }
          },
          {
            "name": "kernel-assembly",
            "component": "_lib/kernel",
            "action": "assemble",
            "stamp": ".stamp.stage3_kernel",
            "variants": [],
            "env": { "LIBSCRIPT_STAGE": "stage3" }
          },
          {
            "name": "initramfs-assembly",
            "component": "_lib/kernel/initramfs",
            "action": "assemble",
            "stamp": ".stamp.stage3_initramfs",
            "variants": [],
            "env": { "LIBSCRIPT_STAGE": "stage3" }
          },
          {
            "name": "media-provisioning",
            "component": "_lib/storage",
            "action": "assemble",
            "stamp": ".stamp.stage3_media",
            "variants": [],
            "env": { "LIBSCRIPT_STAGE": "stage3" }
          }
        ]
      }
    ]
  }

else
  # ----------------------------------------------------
  # TRADITIONAL INSTALL.JSON BACKWARD COMPATIBLE MODE
  # ----------------------------------------------------
  def resolve(reqs; state; manifests; os):
    if (reqs | length) == 0 then
      state
    else
      reqs[0] as $req |
      reqs[1:] as $rest |

      (
        if $req.type == "name" then
          ( [ manifests[] | select((.name | ascii_downcase) == ($req.val | ascii_downcase)) ] | if length == 0 then [{"name": $req.val, "provides": [], "conflicts": []}] else .[0] | .name = $req.val | [.] end ) | map(.version = $req.version | .override = $req.override | .layer = $req.layer)
        elif $req.type == "cap" then
          [ manifests[] | select(.provides != null and (.provides | index($req.val) != null)) ] | map(.version = $req.version | .override = $req.override | .layer = $req.layer)
        elif $req.type == "anyOf" then
          [ manifests[] | select(.name as $n | $req.val | index($n) != null) ] | map(.version = $req.version | .override = $req.override | .layer = $req.layer)
        else
          []
        end
      ) | map(select(is_os_supported(.; os) and
          (
            ($req.version == null or $req.version == "*" or $req.version == "latest") or
            (.versions == null) or
            ( [ .versions[]? | select(semver_satisfies(.; $req.version)) ] | length > 0 )
          )
        )) as $candidates |

      reduce $candidates[] as $c (null;
        if . != null then .
        else
          if [ state.selected[].name ] | index($c.name) != null then
            resolve($rest; state; manifests; os)
          elif intersects([$c.name] + ($c.provides // []); state.conflicts) then
            null
          elif intersects([state.selected[].name] + (state.provided // []); $c.conflicts // []) then
            null
          elif intersects(($req.ports // $c.ports // []); state.ports // []) then
            null
          else
            (if $c.versions == null then ($req.version // "latest") else ($c.versions | max_satisfying(.; $req.version)) end) as $picked_version |
            (state |
             .selected += [$c + {version: $picked_version, override: $req.override, layer: $req.layer}] |
             .conflicts = ((.conflicts + ($c.conflicts // [])) | unique) |
             .provided = ((.provided + ($c.provides // [])) | unique) |
             .ports = ((.ports + ($req.ports // $c.ports // [])) | unique)
            ) as $next_state |
            resolve($rest; $next_state; manifests; os)
          end
        end
      )
    end;

  ($root.install.dependencies.required // {}) as $req |

  (
    [ ($req.databases[]?  | if .name then {layer: "databases", type: "name", val: .name, version: .version, ports: .ports, override: .override} elif .anyOf then {layer: "databases", type: "anyOf", val: .anyOf, version: .version, ports: .ports, override: .override} else empty end) ] +
    [ ($req.servers[]?    | if .name then {layer: "servers", type: "name", val: .name, version: .version, ports: .ports, override: .override} elif .anyOf then {layer: "servers", type: "anyOf", val: .anyOf, version: .version, ports: .ports, override: .override} else empty end) ] +
    [ ($req.toolchains[]? | if .name then {layer: "toolchains", type: "name", val: .name, version: .version, ports: .ports, override: .override} elif .anyOf then {layer: "toolchains", type: "anyOf", val: .anyOf, version: .version, ports: .ports, override: .override} else empty end) ] +
    [ ($req.capabilities[]? | {type: "cap", val: .}) ] +
    [ ($root.install.wwwroot[]?.dependencies.required.capabilities[]? | {type: "cap", val: .}) ] +
    [ ($root.install.wwwroot[]?.dependencies.required.databases[]?  | if .name then {layer: "databases", type: "name", val: .name, version: .version, ports: .ports, override: .override} elif .anyOf then {layer: "databases", type: "anyOf", val: .anyOf, version: .version, ports: .ports, override: .override} else empty end) ] +
    [ ($root.install.wwwroot[]?.dependencies.required.servers[]?    | if .name then {layer: "servers", type: "name", val: .name, version: .version, ports: .ports, override: .override} elif .anyOf then {layer: "servers", type: "anyOf", val: .anyOf, version: .version, ports: .ports, override: .override} else empty end) ] +
    [ ($root.install.wwwroot[]?.dependencies.required.toolchains[]? | if .name then {layer: "toolchains", type: "name", val: .name, version: .version, ports: .ports, override: .override} elif .anyOf then {layer: "toolchains", type: "anyOf", val: .anyOf, version: .version, ports: .ports, override: .override} else empty end) ] 
  ) as $requirements |

  resolve($requirements; {selected: [], conflicts: [], provided: [], ports: []}; $root.manifests; $target_os) as $solution |

  if $solution == null then
    error("UNSATISFIABLE: Could not resolve capabilities and constraints. Check install.json and component manifests.")
  else
    $solution
  end
end
