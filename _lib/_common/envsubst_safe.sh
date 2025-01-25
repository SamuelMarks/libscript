#!/bin/sh

# A safe version of `envsubst`
# If a var is not found it leaves it
# env -i BAR='haz'   "FOO ${BAR} CAN" -> "FOO haz CAN"
# env -i             "FOO ${BAR} CAN" -> "FOO ${BAR} CAN"
# recommend using within a `clear_environment` (`env -i`); see my `environ.sh`
envsubst_safe() {
  input=''

  if [ "$#" -gt 0 ] && [ -n "$1" ]; then
    if [ -f "$1" ]; then
      input="$(cat -- "${1}"; printf 'a')"
      input="${input%a}"
    else
      input="${1}"
    fi
  else
    if [ -t 0 ]; then
      >&2 'No input provided.\n'
      exit 2
    else
      input="$(cat)"
    fi
  fi

  if [ -z "${input}" ]; then
    >&2 'Input is empty.\n'
    exit 2
  fi

  input_len=${#input}

  eaten=0
  tmp="${input}"
  output=''

  while [ -n "${tmp}" ]; do
    rest="${tmp#?}"
    ch="${tmp%"$rest"}"
    tmp="${rest}"
    # shellcheck disable=SC2003
    eaten="$(expr "${eaten}" + 1)"

    if [ "${ch}" = '$' ]; then
      if [ -n "${tmp}" ]; then
        rest="${tmp#?}"
        next_ch="${tmp%"$rest"}"

        if [ "${next_ch}" = '{' ]; then
          tmp="${rest}"
          # shellcheck disable=SC2003
          eaten="$(expr "${eaten}" + 1)"
          var_name=''
          found_closing_brace=0
          while [ -n "${tmp}" ]; do
            rest="${tmp#?}"
            ch="${tmp%"${rest}"}"
            tmp="${rest}"
            # shellcheck disable=SC2003
            eaten="$(expr "${eaten}" + 1)"
            if [ "${ch}" = '}' ]; then
              found_closing_brace=1
              break
            else
              var_name="${var_name}${ch}"
            fi
          done
          if [ "${found_closing_brace}" -eq 0 ]; then
            output="${output}\${${var_name}"
          else
            if eval "[ \"\${$var_name+set}\" = \"set\" ]"; then
              var_value="$(eval "printf '%s' \"\${$var_name}\"")"
              output="${output}${var_value}"
            else
              output="${output}\${${var_name}}"
            fi
          fi
        elif printf '%s' "${next_ch}" | grep -q '[a-zA-Z0-9_]'; then
          var_name=''
          while [ -n "${tmp}" ]; do
            rest="${tmp#?}"
            ch="${tmp%"$rest"}"
            if printf '%s' "${ch}" | grep -qv '[a-zA-Z0-9_]'; then
              break
            else
              var_name="${var_name}${ch}"
              tmp="${rest}"
              # shellcheck disable=SC2003
              eaten="$(expr "${eaten}" + 1)"
            fi
          done
          if eval "[ \"\${$var_name+set}\" = \"set\" ]"; then
            var_value="$(eval "printf '%s' \"\${$var_name}\"")"
            output="${output}${var_value}"
          else
            output="${output}\$${var_name}"
          fi
        else
          output="${output}\$"
        fi
      else
        output="${output}\$"
      fi
    else
      output="${output}${ch}"
    fi
  done
  if [ "${eaten}" -ne "${input_len}" ]; then
    >&2 printf 'Did not parse all of input: %d != %d\n' "${eaten}" "${input_len}"
    exit 4
  fi
  printf '%s' "${output}"
}
