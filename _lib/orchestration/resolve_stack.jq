include "semver";

def intersects(a; b):
  if a == null or b == null then false else
  [ (a[]?) as $x | (b[]?) as $y | select($x == $y) ] | length > 0
  end;

def is_os_supported(m; os):
  (m.os_blacklist // [] | index(os) == null) and
  (m.os_whitelist == null or (m.os_whitelist | length == 0) or (m.os_whitelist | index("all")) or (m.os_whitelist | index(os) != null));

def resolve(reqs; state; manifests; os):
  if (reqs | length) == 0 then
    state
  else
    reqs[0] as $req |
    reqs[1:] as $rest |

    (
      if $req.type == "name" then
        ( [ manifests[] | select(.name == ($req.val | ascii_upcase)) ] | if length == 0 then [{"name": $req.val, "provides": [], "conflicts": []}] else .[0] | .name = $req.val | [.] end )
      elif $req.type == "cap" then
        [ manifests[] | select(.provides != null and (.provides | index($req.val) != null)) ]
      elif $req.type == "anyOf" then
        [ manifests[] | select(.name as $n | $req.val | index($n) != null) ]
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
          (($c.versions // ["latest"]) | max_satisfying(.; $req.version)) as $picked_version |
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

. as $root |
.install as $install |
($install.dependencies.required // {}) as $req |

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
