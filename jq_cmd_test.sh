l_filter="toolchains,deps"
jq_expr="to_entries[] | .key as \$layer | if (\$layer | IN(\"deps\", \"toolchains\", \"servers\", \"databases\", \"third_party\", \"storage\")) then (.value | to_entries[] | \"\\(\$layer) \\(.key) \\(if (.value | type) == \\\"string\\\" then .value else (.value.version // \\\"latest\\\") end) \\(if (.value | type) == \\\"object\\\" and .value.override then .value.override else \\\"\\\" end)\") else empty end"

if [ -n "$l_filter" ]; then
    IFS=',' read -r -a layers <<< "$l_filter"
    jq_layers=()
    for l in "${layers[@]}"; do
        jq_layers+=("\"$l\"", "\"${l}s\"")
    done
    jq_in=$(IFS=, ; echo "${jq_layers[*]}")
    jq_expr="to_entries[] | .key as \$layer | if (\$layer | IN(${jq_in})) then (.value | to_entries[] | \"\\(.key) \\(if (.value | type) == \\\"string\\\" then .value else (.value.version // \\\"latest\\\") end) \\(if (.value | type) == \\\"object\\\" and .value.override then .value.override else \\\"\\\" end)\") else empty end"
fi
echo "$jq_expr"
