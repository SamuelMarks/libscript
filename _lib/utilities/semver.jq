def parse_ver:
  if type != "string" then [0,0,0] else
  [scan("[0-9]+")] | map(tonumber) |
  [ (.[0] // 0), (.[1] // 0), (.[2] // 0) ]
  end;

def compare_ver(a; b):
  if a[0] != b[0] then (a[0] - b[0])
  elif a[1] != b[1] then (a[1] - b[1])
  elif a[2] != b[2] then (a[2] - b[2])
  else 0 end;

def semver_satisfies(v; c):
  if c == null or c == "*" or c == "latest" or c == "" then true
  else
    (c | capture("^(?<op>[<>=^~]*)\\s*(?<ver>.*)$") // {op: "=", ver: c}) as $parsed |
    (if $parsed.op == "" then "=" else $parsed.op end) as $op |
    (v | parse_ver) as $v_arr |
    ($parsed.ver | parse_ver) as $c_arr |
    (compare_ver($v_arr; $c_arr)) as $cmp |
    if $op == ">=" then $cmp >= 0
    elif $op == "<=" then $cmp <= 0
    elif $op == ">" then $cmp > 0
    elif $op == "<" then $cmp < 0
    elif $op == "^" then ($cmp >= 0 and $v_arr[0] == $c_arr[0])
    elif $op == "~" then ($cmp >= 0 and $v_arr[0] == $c_arr[0] and $v_arr[1] == $c_arr[1])
    elif $op == "=" then $cmp == 0
    else false
    end
  end;

def max_satisfying(versions; c):
  if (versions == null or (versions | length == 0)) then "latest"
  else
    [versions[] | select(semver_satisfies(.; c))] |
    if length == 0 then null else
      sort_by(parse_ver) | last
    end
  end;
