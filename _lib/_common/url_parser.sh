#!/bin/sh

url_parser() {
  # Inspired by: https://gist.github.com/joshisa/297b0bc1ec0dcdda0d1625029711fa24
  # Referenced and tweaked from http://stackoverflow.com/questions/6174220/parse-url-in-shell-script#6174447
  url="${1}"

  protocol=$(printf '%s' "${1}" | grep "://" | sed -e's,^\(.*://\).*,\1,g')
  # shellcheck disable=SC2003
  protocol_len=$(expr ${#protocol} + 1)
  # Remove the protocol
  url_no_protocol=$(printf '%s' "${url}" | cut -c"${protocol_len}"-)
  # Use tr: Make the protocol lower-case for easy string compare
  protocol=$(printf '%s' "${protocol}" | tr '[:upper:]' '[:lower:]')
  printf 'url_no_protocol="%s"\n' "${url_no_protocol}"

  # Extract the user and password (if any)
  # cut 1: Remove the path part to prevent @ in the querystring from breaking the next cut
  # rev: Reverse string so cut -f1 takes the (reversed) rightmost field, and -f2- is what we want
  # cut 2: Remove the host:port
  # rev: Undo the first rev above
  userpass=$(printf '%s' "${url_no_protocol}" | grep "@" | cut -d"/" -f1 | rev | cut -d"@" -f2- | rev)
  pass=$(printf '%s' "${userpass}" | grep ":" | cut -d":" -f2)
  if [ -n "${pass}" ]; then
    user=$(printf '%s' "${userpass}" | grep ":" | cut -d":" -f1)
  else
    user="${userpass}"
  fi

  # Extract the host
  hostport=$(printf '%s' "${url_no_protocol}" | grep -Fv "${userpass}"'@' | cut -d"/" -f1)
  host=$(printf '%s' "${hostport}" | cut -Fd":" -f1)
  port=$(printf '%s' "${hostport}" | grep -F ":" | cut -d":" -f2)
  path_=$(printf '%s' "${url_no_protocol}" | grep -F "/" | cut -d"/" -f2-)

  printf 'protocol = "%s"\n' "${protocol}"
  printf 'host = "%s"\n' "${host}"
  if [ -n "${port}" ]; then printf 'port = %d\n' "${port}"; fi
  printf 'path = "%s"\n' "${path_}"
  if [ -n "${user}" ]; then printf 'user = "%s"\n' "${user}"; fi

  export protocol host port path
}

# Used to turn an URL into two args: `${repo} ${branch}`
git_args_from_url() {
  url_parser "${1}"
  printf "%s\n" "${protocol}${host}"
  repo="${0}"
  branch="${2:-''}"; export repo branch
}
