# LibScript Dependency Resolution & Variant Solver (`resolve_stack.jq`)
#
# Implements:
# - Unified multi-kernel resolution across Linux, FreeBSD, illumos (sunos), and Unikernels
#   (Unikraft, Nanos/Ops, OSv, Rumprun, MirageOS) plus Firecracker microVMs
# - Full recursive transitive dependency closure in both os-config.json and install.json modes
# - Virtual capability satisfaction (`provides`) and OS-conditional filtering
# - Unikernel `process_model` compatibility checks and automatic multi-unikernel pod synthesis
# - Tarjan's strongly connected components (SCC) cycle breaking and topological sorting

include "semver";

def intersects(a; b):
  if a == null or b == null then false else
  [ (a[]?) as $x | (b[]?) as $y | select($x == $y) ] | length > 0
  end;

def effective_check_os(os):
  if os == "unikraft" or os == "nanos" or os == "osv" or os == "rumprun" or os == "mirageos" then "linux"
  else os
  end;

def is_os_supported(m; os):
  effective_check_os(os) as $chk |
  (m.os_blacklist // [] | index($chk) == null) and
  (m.os_whitelist == null or (m.os_whitelist | length == 0) or (m.os_whitelist | index("all")) or (m.os_whitelist | index($chk) != null));

def map_os_family_to_target(os_fam; fallback_os):
  if os_fam == null or os_fam == "" then fallback_os
  elif (os_fam | startswith("freebsd")) then "freebsd"
  elif (os_fam == "illumos" or os_fam == "sunos") then "sunos"
  elif (os_fam == "unikernel-unikraft" or (os_fam | startswith("unikraft"))) then "unikraft"
  elif (os_fam == "unikernel-nanos" or (os_fam | startswith("nanos"))) then "nanos"
  elif (os_fam == "unikernel-osv" or (os_fam | startswith("osv"))) then "osv"
  elif (os_fam == "unikernel-rumprun" or (os_fam | startswith("rumprun"))) then "rumprun"
  elif (os_fam == "unikernel-mirageos" or (os_fam | startswith("mirage"))) then "mirageos"
  elif (os_fam | startswith("linux")) or os_fam == "microvm-firecracker" then "linux"
  else fallback_os
  end;

def is_single_process_unikernel(os):
  os == "unikraft" or os == "nanos" or os == "rumprun" or os == "mirageos";

def is_unikernel_os(os):
  is_single_process_unikernel(os) or os == "osv";

def normalize_os_pkg_alias(name; os; libc):
  (name | tostring) as $raw |
  ($raw | ascii_downcase) as $n |
  if $n == "postgresql" then "postgres"
  elif $n == "node" then "nodejs"
  elif $n == "smtp" then (if os == "windows" then "hmailserver" else "exim" end)
  elif $n == "wsgi" then (if os == "windows" then "waitress" else "gunicorn" end)
  elif $n == "mongodb-compatible" then (if os == "sunos" or libc == "musl" or is_unikernel_os(os) then "ferretdb" else "mongodb" end)
  elif $n == "kv-store" then "redis"
  elif $n == "rdbms" then "mysql"
  elif $n == "search" then "meilisearch"
  else $raw
  end;

def lookup_manifest(manifests; pkg; os; libc):
  normalize_os_pkg_alias(pkg; os; libc) as $norm |
  ([ manifests[]? | select((.name // "" | ascii_downcase) == ($norm | ascii_downcase)) ]) as $by_name |
  if ($by_name | length) > 0 then $by_name[0]
  else
    ([ manifests[]? | select((.provides // [] | index($norm) != null) and is_os_supported(.; os)) ]) as $by_cap |
    if ($by_cap | length) > 0 then $by_cap[0]
    else null
    end
  end;

# Recursive transitive dependency graph builder for os-config mode
def expand_os_graph(queue; graph; manifests; os; libc):
  if (queue | length) == 0 then graph
  else
    (normalize_os_pkg_alias(queue[0]; os; libc)) as $curr |
    queue[1:] as $rest |
    if (graph | has($curr)) then
      expand_os_graph($rest; graph; manifests; os; libc)
    else
      lookup_manifest(manifests; $curr; os; libc) as $m |
      (if $m != null then
        [
          (($m.dependencies?.host_tools // []) + ($m.dependencies?.build_deps // []) + ($m.dependencies?.runtime_deps // []))[]?
          | normalize_os_pkg_alias(.; os; libc)
          | . as $dep_name
          | (lookup_manifest(manifests; $dep_name; os; libc)) as $dm
          | select($dm == null or is_os_supported($dm; os))
          | (if $dm != null then $dm.name else $dep_name end)
        ] | unique
      else [] end) as $deps |
      expand_os_graph(($rest + $deps) | unique; graph + { ($curr): $deps }; manifests; os; libc)
    end
  end;

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

def tarjan_scc(graph):
  reduce (graph | keys)[] as $node (
    { index: 0, stack: [], indices: {}, lowlinks: {}, on_stack: {}, sccs: [] };
    if .indices[$node] == null then
      strongconnect($node; graph)
    else . end
  ) | .sccs;

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

def topological_sort(graph; cyclic_edges):
  (reduce (graph | keys)[] as $u (
    {};
    .[$u] = [ (graph[$u] // [])[] | select(($u + "->" + .) as $edge | cyclic_edges | index($edge) == null) ]
  )) as $dag |
  reduce ($dag | keys)[] as $node (
    { visited: {}, order: [] };
    topo_visit($node; $dag)
  ) | .order;

. as $root |
($root.config // $root.install // $root) as $cfg |

if ($cfg.target != null and ($cfg.target.os_family != null or $cfg.target.libc != null)) then
  # ----------------------------------------------------
  # OS-CONFIG.JSON MULTI-KERNEL RESOLUTION MODE
  # ----------------------------------------------------
  ($cfg.target.arch // "x86_64") as $arch |
  ($cfg.target.os_family // "linux-glibc") as $os_fam |
  map_os_family_to_target($os_fam; ($target_os // "linux")) as $resolved_os |
  ($cfg.target.libc // (
    if $resolved_os == "freebsd" then "bsd-libc"
    elif $resolved_os == "sunos" then "illumos-libc"
    elif $resolved_os == "rumprun" then "rump-libc"
    elif $resolved_os == "mirageos" then "mirage-ocaml"
    elif $os_fam == "linux-musl" then "musl"
    else "glibc" end
  )) as $libc |
  ($cfg.profile_name // "custom") as $profile |
  ($cfg.kernel.compiler // "default") as $kcompiler |
  ($cfg.kernel.version // "6.6.52") as $kversion |
  ($cfg.kernel.config_method // "defconfig") as $kconfig |
  ($cfg.kernel.kcflags // "-O2") as $kkcflags |
  ($cfg.kernel.custom_cc_bin // "") as $kcustom_bin |
  ($root.manifests // []) as $manifests |

  [
    (if $cfg.display?.server == "wayland" or ($cfg.display?.compositor != null and $cfg.display?.compositor != "none") then "wayland" else empty end),
    (if $cfg.display?.server == "x11" then "x11" else empty end),
    (if $cfg.init_system?.provider == "systemd" then "systemd" else empty end),
    (if $cfg.init_system?.provider == "openrc" then "openrc" else empty end),
    (if $cfg.init_system?.provider == "smf" then "smf" else empty end),
    (if $cfg.audio?.subsystem == "pipewire" or ($cfg.desktop?.desktop_suite != null and $cfg.desktop?.desktop_suite != "none") then "pipewire" else empty end),
    $libc
  ] | unique as $global_variants |

  (($cfg.packages // []) + ($cfg.components // [])) as $raw_user_pkgs |
  ([ $raw_user_pkgs[] | normalize_os_pkg_alias(.; $resolved_os; $libc) ]) as $user_pkgs |

  # Validate OS blacklist & unikernel process_model compatibility on explicitly requested components
  (
    reduce $user_pkgs[] as $upkg (
      [];
      (lookup_manifest($manifests; $upkg; $resolved_os; $libc) // ([ $manifests[]? | select(.name == $upkg) ][0])) as $um |
      if $um != null then
        if ($resolved_os == "freebsd" or $resolved_os == "sunos" or $resolved_os == "linux") and (is_os_supported($um; $resolved_os) | not) then
          error("OS_UNSUPPORTED: Component '" + $upkg + "' is not supported on target OS '" + $resolved_os + "'.")
        elif is_unikernel_os($resolved_os) and ($um.process_model == "multiprocess-fork") and (($um.unikernel_support // ["osv", "nanos"]) | index($resolved_os) == null) then
          error("UNIKERNEL_INCOMPATIBLE: Component '" + $upkg + "' requires multiprocess fork() which is unsupported on '" + $resolved_os + "'. Choose osv/nanos or a hybrid multi-VM topology.")
        else . end
      else . end
    )
  ) as $_validated |

  ([
    (if $resolved_os == "linux" then (if $libc == "musl" then "musl" else "glibc" end) else empty end),
    (if $resolved_os == "linux" and $cfg.kernel?.provider and $cfg.kernel.provider != "none" then $cfg.kernel.provider else empty end),
    (if ($resolved_os == "linux" or $resolved_os == "freebsd" or $resolved_os == "sunos") and $cfg.init_system?.provider and $cfg.init_system.provider != "none" and $cfg.init_system.provider != "unikernel-entrypoint" then $cfg.init_system.provider else empty end),
    (if $resolved_os == "linux" and $cfg.storage?.bootloader and $cfg.storage.bootloader != "none" then $cfg.storage.bootloader else empty end),
    (if $cfg.display?.compositor and $cfg.display.compositor != "none" then $cfg.display.compositor else empty end),
    (if $cfg.desktop?.desktop_suite and $cfg.desktop.desktop_suite != "none" then $cfg.desktop.desktop_suite else empty end),
    (if $cfg.desktop?.greeter and $cfg.desktop.greeter != "none" then $cfg.desktop.greeter else empty end)
  ] + $user_pkgs) | unique as $seed_components |

  expand_os_graph($seed_components; {}; $manifests; $resolved_os; $libc) as $dep_graph |

  (tarjan_scc($dep_graph) | map(select(length > 1))) as $cycles |
  [
    $cycles[] |
    . as $cycle |
    range(0; length) as $i |
    ($cycle[$i] + "->" + $cycle[($i + 1) % length])
  ] as $cyclic_edges |

  # Reverse topo_visit post-order so dependencies execute BEFORE dependents!
  (topological_sort($dep_graph; $cyclic_edges) | reverse) as $sorted_packages |

  # Count daemon/service components to determine single-unikernel vs multi-unikernel pod synthesis
  ([
    $sorted_packages[] |
    . as $p |
    lookup_manifest($manifests; $p; $resolved_os; $libc) as $pm |
    select($pm != null and (($pm.ports // [] | length > 0) or ($pm.stateful == true) or ($pm.category == "web-servers" or $pm.category == "app-servers" or $pm.category == "databases" or $pm.category == "caches" or $pm.category == "search" or $pm.category == "web-apps"))) |
    $p
  ] | unique) as $daemon_packages |

  (is_single_process_unikernel($resolved_os) and (($daemon_packages | length) > 1)) as $needs_unikernel_pod |

  {
    "plan_version": "1.0.0",
    "profile_name": $profile,
    "execution_mode": (
      if $needs_unikernel_pod then "multi-unikernel-pod"
      elif is_unikernel_os($resolved_os) then "single-unikernel"
      else "sysroot-image" end
    ),
    "target": {
      "arch": $arch,
      "libc": $libc,
      "os": $resolved_os,
      "os_family": $os_fam,
      "compiler": $kcompiler
    },
    "stages": (
      if $resolved_os == "linux" then
        [
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
                "name": (if $kcompiler == "default" then "gcc-pass1" else ($kcompiler + "-pass1") end),
                "component": (if $kcompiler == "default" then "_lib/toolchains/gcc" else ("_lib/languages/" + $kcompiler) end),
                "action": "bootstrap",
                "stamp": (".stamp.stage0_" + (if $kcompiler == "default" then "gcc" else $kcompiler end) + "_pass1"),
                "variants": ["bootstrap", "static"],
                "env": {
                  "LIBSCRIPT_STAGE": "stage0",
                  "CC_BACKEND": $kcompiler,
                  "CUSTOM_CC_BIN": $kcustom_bin
                }
              }
            ]
          },
          {
            "stage": "stage1-cross-tools",
            "description": "Minimal cross-compiled Linux userland for clean build isolation",
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
          }
        ]
      elif $resolved_os == "freebsd" then
        [
          {
            "stage": "stage1-freebsd-base",
            "description": "FreeBSD base.txz and kernel.txz sysroot bootstrap",
            "tasks": [
              {
                "name": "freebsd-base",
                "component": "_lib/freebsd/distro",
                "action": "bootstrap",
                "stamp": ".stamp.stage1_freebsd_base",
                "variants": [],
                "env": {
                  "LIBSCRIPT_STAGE": "stage1",
                  "LIBSCRIPT_TARGET_OS": "freebsd",
                  "LIBSCRIPT_TARGET_ARCH": $arch
                }
              }
            ]
          }
        ]
      elif $resolved_os == "sunos" then
        [
          {
            "stage": "stage1-illumos-base",
            "description": "illumos proto-root, ZFS dataset layout, and IPS/pkgin/zap bootstrap",
            "tasks": [
              {
                "name": "illumos-base",
                "component": "_lib/illumos/distro",
                "action": "bootstrap",
                "stamp": ".stamp.stage1_illumos_base",
                "variants": [],
                "env": {
                  "LIBSCRIPT_STAGE": "stage1",
                  "LIBSCRIPT_TARGET_OS": "sunos",
                  "LIBSCRIPT_TARGET_ARCH": $arch
                }
              }
            ]
          }
        ]
      else
        [
          {
            "stage": "stage0-unikernel-sdk",
            "description": ("Host unikernel SDK bootstrap for " + $resolved_os),
            "tasks": [
              {
                "name": ($resolved_os + "-sdk"),
                "component": (
                  if $resolved_os == "mirageos" then "_lib/orchestration/mirage"
                  else ("_lib/orchestration/" + $resolved_os) end
                ),
                "action": "bootstrap",
                "stamp": (".stamp.stage0_" + $resolved_os + "_sdk"),
                "variants": [],
                "env": {
                  "LIBSCRIPT_STAGE": "stage0",
                  "LIBSCRIPT_UNIKERNEL_FRAMEWORK": $resolved_os
                }
              }
            ]
          }
        ]
      end
      +
      [
        {
          "stage": "stage2-target-sysroot",
          "description": "Target component staging with active USE flags and transitive dependencies",
          "tasks": [
            $sorted_packages[] |
            . as $pkg |
            (lookup_manifest($manifests; $pkg; $resolved_os; $libc) // {name: $pkg, category: "base-system"}) as $manifest |
            ([ ($manifest.variants // {} | keys)[] | select(. as $v | $global_variants | index($v) != null) ]) as $pkg_variants |
            {
              "name": ($manifest.name // $pkg),
              "component": ($manifest._manifest_dir // ("_lib/" + ($manifest.category // "base-system") + "/" + ($manifest.name // $pkg))),
              "action": "compile",
              "stamp": (".stamp." + ($manifest.name // $pkg)),
              "variants": $pkg_variants,
              "env": {
                "LIBSCRIPT_STAGE": "stage2",
                "LIBSCRIPT_TARGET_ARCH": $arch,
                "LIBSCRIPT_TARGET_LIBC": $libc,
                "LIBSCRIPT_TARGET_OS": $resolved_os,
                "LIBSCRIPT_IMAGE_BUILD": "1"
              }
            }
          ]
        },
        (
          if $resolved_os == "linux" then
            {
              "stage": "stage3-media-packaging",
              "description": "Linux kernel injection, initramfs synthesis, and bootable image assembly",
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
                  "component": "_lib/kernel/linux",
                  "action": "compile",
                  "stamp": (".stamp.stage3_kernel_" + $kcompiler + "_" + $kconfig),
                  "variants": [],
                  "env": {
                    "LIBSCRIPT_STAGE": "stage3",
                    "LINUX_VERSION": $kversion,
                    "LINUX_BUILD_TOOLCHAIN": $kcompiler,
                    "LINUX_COMPILER": $kcompiler,
                    "LINUX_CONFIG_TARGET": $kconfig,
                    "LINUX_KCFLAGS": $kkcflags,
                    "CUSTOM_CC_BIN": $kcustom_bin
                  }
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
          elif $resolved_os == "freebsd" then
            {
              "stage": "stage3-media-packaging",
              "description": "FreeBSD kernel/loader configuration and UFS2/ZFS bootable media synthesis",
              "tasks": [
                {
                  "name": "freebsd-kernel-loader",
                  "component": "_lib/freebsd",
                  "action": "assemble",
                  "stamp": ".stamp.stage3_freebsd_kernel",
                  "variants": [],
                  "env": { "LIBSCRIPT_STAGE": "stage3", "LIBSCRIPT_TARGET_OS": "freebsd" }
                }
              ]
            }
          elif $resolved_os == "sunos" then
            {
              "stage": "stage3-media-packaging",
              "description": "illumos rpool ZFS boot environment, boot_archive, and SMF repository finalization",
              "tasks": [
                {
                  "name": "illumos-boot-archive",
                  "component": "_lib/illumos/distro",
                  "action": "assemble",
                  "stamp": ".stamp.stage3_illumos_archive",
                  "variants": [],
                  "env": { "LIBSCRIPT_STAGE": "stage3", "LIBSCRIPT_TARGET_OS": "sunos" }
                }
              ]
            }
          elif $needs_unikernel_pod then
            {
              "stage": "stage3-unikernel-pod",
              "description": ("Decomposed multi-unikernel appliance pod synthesis for " + ($daemon_packages | join(", "))),
              "tasks": [
                {
                  "name": "unikernel-pod-assembly",
                  "component": "_lib/orchestration/unikernel_pod",
                  "action": "assemble",
                  "stamp": (".stamp.stage3_unikernel_pod_" + $resolved_os),
                  "variants": [],
                  "env": {
                    "LIBSCRIPT_STAGE": "stage3",
                    "LIBSCRIPT_UNIKERNEL_FRAMEWORK": $resolved_os,
                    "LIBSCRIPT_POD_DAEMONS": ($daemon_packages | join(","))
                  }
                }
              ]
            }
          else
            {
              "stage": "stage3-unikernel-image",
              "description": ("Single-address-space " + $resolved_os + " unikernel image synthesis"),
              "tasks": [
                {
                  "name": ("unikernel-" + $resolved_os + "-image"),
                  "component": (
                    if $resolved_os == "mirageos" then "_lib/orchestration/mirage"
                    else ("_lib/orchestration/" + $resolved_os) end
                  ),
                  "action": "assemble",
                  "stamp": (".stamp.stage3_unikernel_" + $resolved_os),
                  "variants": [],
                  "env": {
                    "LIBSCRIPT_STAGE": "stage3",
                    "LIBSCRIPT_UNIKERNEL_FRAMEWORK": $resolved_os
                  }
                }
              ]
            }
          end
        )
      ]
    )
  }

else
  # ----------------------------------------------------
  # TRADITIONAL INSTALL.JSON & MODERN LIBSCRIPT.JSON MODE
  # ----------------------------------------------------
  def normalize_pkg_alias(name):
    (name | tostring | ascii_downcase) as $n |
    if $n == "postgresql" then "postgres"
    elif $n == "node" then "nodejs"
    elif $n == "redis" then "valkey"
    else name
    end;

  def make_dep_req(raw_name; layer_name; manifests):
    normalize_pkg_alias(raw_name) as $norm |
    if ([ manifests[]? | select((.name // "" | ascii_downcase) == ($norm | ascii_downcase)) ] | length) > 0 then
      {layer: layer_name, type: "name", val: $norm, version: "latest"}
    elif ([ manifests[]? | select(.provides != null and (.provides | index($norm) != null)) ] | length) > 0 then
      {layer: layer_name, type: "cap", val: $norm, version: "latest"}
    else
      {layer: layer_name, type: "name", val: $norm, version: "latest"}
    end;

  def parse_dep_item(layer_name):
    if type == "string" then
      make_dep_req(.; layer_name; ($root.manifests // []))
    elif type == "object" then
      if .name then
        {layer: layer_name, type: "name", val: normalize_pkg_alias(.name), version: ((.version // "latest") | tostring), ports: .ports, override: .override}
      elif .anyOf then
        {layer: layer_name, type: "anyOf", val: ([.anyOf[] | normalize_pkg_alias(.)]), version: ((.version // "latest") | tostring), ports: .ports, override: .override}
      else
        empty
      end
    else
      empty
    end;

  def extract_db_engine:
    if type == "object" then
      (if .engine != null or .type != null then
        [{layer: "databases", type: "name", val: normalize_pkg_alias(.engine // .type), version: ((.version // "latest") | tostring)}]
      else
        [ to_entries[] | select((.value | type) == "object") | {layer: "databases", type: "name", val: normalize_pkg_alias(.value.engine // .value.type // "postgres"), version: ((.value.version // "latest") | tostring)} ]
      end)
    elif type == "array" then
      [ .[] | select(type == "object") | {layer: "databases", type: "name", val: normalize_pkg_alias(.engine // .type // "postgres"), version: ((.version // "latest") | tostring)} ]
    else
      []
    end;

  def resolve(reqs; state; manifests; os):
    if (reqs | length) == 0 then
      state
    else
      reqs[0] as $req |
      reqs[1:] as $rest |

      (
        if $req.type == "name" then
          ( [ manifests[]? | select((.name // "" | ascii_downcase) == ($req.val | ascii_downcase)) ] | if length == 0 then [{"name": $req.val, "provides": [], "conflicts": []}] else .[0] | .name = $req.val | [.] end ) | map(.version = $req.version | .override = $req.override | .layer = $req.layer)
        elif $req.type == "cap" then
          [ manifests[]? | select(.provides != null and (.provides | index($req.val) != null)) ] | map(.version = $req.version | .override = $req.override | .layer = $req.layer)
        elif $req.type == "anyOf" then
          ( [ manifests[]? | select(.name as $n | $req.val | index($n) != null) ] | if length == 0 then [{"name": $req.val[0], "provides": [], "conflicts": []}] else . end ) | map(.version = $req.version | .override = $req.override | .layer = $req.layer)
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
          if ([ state.selected[].name ] + (state.provided // [])) | index($req.val) != null then
            resolve($rest; state; manifests; os)
          elif [ state.selected[].name ] | index($c.name) != null then
            resolve($rest; state; manifests; os)
          elif intersects([$c.name] + ($c.provides // []); state.conflicts) then
            null
          elif intersects([state.selected[].name] + (state.provided // []); $c.conflicts // []) then
            null
          elif intersects(($req.ports // $c.ports // []); state.ports // []) then
            null
          else
            (if $c.versions == null then ($req.version // "latest") else ($c.versions | max_satisfying(.; $req.version)) end) as $picked_version |
            ([ (($c.dependencies?.runtime_deps // []) + ($c.dependencies?.build_deps // []))[]? | make_dep_req(.; ($req.layer // "deps"); manifests) ]) as $trans_reqs |
            (state |
             .selected += [$c + {version: $picked_version, override: $req.override, layer: $req.layer}] |
             .conflicts = ((.conflicts + ($c.conflicts // [])) | unique) |
             .provided = ((.provided + ($c.provides // [])) | unique) |
             .ports = ((.ports + ($req.ports // $c.ports // [])) | unique)
            ) as $next_state |
            resolve($trans_reqs + $rest; $next_state; manifests; os)
          end
        end
      )
    end;

  ($root.config // $root) as $doc |
  ($doc.install.dependencies.required // {}) as $req |
  ($doc.deps // {}) as $flat_deps |
  ($doc.dependencies // {}) as $struct_deps |
  ($doc.databases // $doc.infrastructure.databases // null) as $decl_dbs |

  (
    [ ($flat_deps | if type == "object" then to_entries[] | make_dep_req(.key; "deps"; ($root.manifests // [])) * {version: (if .value == null or .value == "" then "latest" else (.value | tostring) end)} elif type == "array" then .[] | parse_dep_item("deps") else empty end) ] +
    [ ($struct_deps | if type == "array" then .[] | parse_dep_item("runtime") elif type == "object" then (
        ((.runtime // [])[]? | parse_dep_item("runtime")),
        ((.build // [])[]? | parse_dep_item("build")),
        ((.optional // [])[]? | parse_dep_item("optional")),
        ((.system // {}) | if type == "array" then .[] | parse_dep_item("system") elif type == "object" then to_entries[] | if (.value | type) == "string" or (.value | type) == "number" then make_dep_req(.key; "system"; ($root.manifests // [])) * {version: (.value | tostring)} elif (.value | type) == "object" then make_dep_req(.key; "system"; ($root.manifests // [])) * {version: ((.value.version // "latest") | tostring)} else empty end else empty end),
        (to_entries[] | select(.key != "runtime" and .key != "build" and .key != "optional" and .key != "required" and .key != "system") | if (.value | type) == "string" or (.value | type) == "number" then make_dep_req(.key; "deps"; ($root.manifests // [])) * {version: (.value | tostring)} elif (.value | type) == "object" then make_dep_req(.key; "deps"; ($root.manifests // [])) * {version: ((.value.version // "latest") | tostring)} else empty end)
      ) else empty end) ] +
    ($decl_dbs | extract_db_engine) +
    [ ($req.databases[]?  | parse_dep_item("databases")) ] +
    [ ($req.servers[]?    | parse_dep_item("servers")) ] +
    [ ($req.toolchains[]? | parse_dep_item("toolchains")) ] +
    [ ($req.capabilities[]? | {type: "cap", val: .}) ] +
    [ ($doc.install.wwwroot[]?.dependencies.required.capabilities[]? | {type: "cap", val: .}) ] +
    [ ($doc.install.wwwroot[]?.dependencies.required.databases[]?  | parse_dep_item("databases")) ] +
    [ ($doc.install.wwwroot[]?.dependencies.required.servers[]?    | parse_dep_item("servers")) ] +
    [ ($doc.install.wwwroot[]?.dependencies.required.toolchains[]? | parse_dep_item("toolchains")) ]
  ) as $requirements |

  resolve($requirements; {selected: [], conflicts: [], provided: [], ports: []}; ($root.manifests // []); $target_os) as $solution |

  if $solution == null then
    error("UNSATISFIABLE: Could not resolve capabilities and constraints. Check install.json and component manifests.")
  else
    $solution
  end
end
