#!/bin/sh

# shellcheck disable=SC2236
if [ ! -z "${SCRIPT_NAME+x}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ ! -z "${BASH_VERSION+x}" ]; then
  # shellcheck disable=SC3028 disable=SC3054
  this_file="${BASH_SOURCE[0]}"
  # shellcheck disable=SC3040
  set -o pipefail
elif [ ! -z "${ZSH_VERSION+x}" ]; then
  # shellcheck disable=SC2296
  this_file="${(%):-%x}"
  # shellcheck disable=SC3040
  set -o pipefail
else
  this_file="${0}"
fi
set -eu +f

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

LIBSCRIPT_DOCS_DIR="${LIBSCRIPT_DOCS_DIR:-./docs/latest}"
export LIBSCRIPT_DOCS_DIR

LIBSCRIPT_ASSETS_DIR="${LIBSCRIPT_ASSETS_DIR:-${LIBSCRIPT_DOCS_DIR}}"
export LIBSCRIPT_ASSETS_DIR

HTML_ROOT="${HTML_ROOT:-$LIBSCRIPT_ROOT_DIR}"
export HTML_ROOT

[ -d "${LIBSCRIPT_DOCS_DIR}" ] || mkdir -p "${LIBSCRIPT_DOCS_DIR}"
#cp 'tuicss.min.css' "${LIBSCRIPT_DOCS_DIR}"'/'
#cp 'tuicss.min.js' "${LIBSCRIPT_DOCS_DIR}"'/'
#cp 'styles.css' "${LIBSCRIPT_DOCS_DIR}"'/'
urls_js='['
urls=''
export LIBSCRIPT_DOCS_PREFIX="${LIBSCRIPT_DOCS_PREFIX:-}"
find_res="$(mktemp)"
find "${LIBSCRIPT_ROOT_DIR}" -type f -name '*.md' > "${find_res}"
while IFS= read -r f; do
  out="${LIBSCRIPT_DOCS_DIR}${f#"${LIBSCRIPT_ROOT_DIR}"}"
  parent="$(dirname -- "${out}")"

  slashes=0
  tmp="${out}"

  while [ -n "${tmp}" ]; do
    rest="${tmp#?}"
    ch="${tmp%"$rest"}"
    tmp="${rest}"
    if [ "${ch}" = '/' ]; then
      # shellcheck disable=SC2003
      slashes=$(expr "${slashes}" + 1)
    fi
  done
  case "${out}" in
    './'*)
      if [ "${slashes}" -gt 1 ] ; then
        [ -d "${parent}" ] || mkdir -p -- "${parent}"
      fi
      ;;
    *'/'*)
      [ -d "${parent}" ] || mkdir -p -- "${parent}"
      ;;
  esac

  html="${out%%.md}"'.html'

  cp -- "${HTML_ROOT}"'/html/top.html' "${html}"
  iconv -t utf-8 -- "${f}" | sed 's/.md)/.html)/g' | pandoc -f markdown -t html5 | iconv -f utf-8 >> "${html}"
  previous_wd="$(pwd)"
  new_wd="${f%/*}"
  cd -- "${new_wd}"
  for json_schema in *'.schema.json'; do
    if [ -f "${json_schema}" ]; then
      case "${json_schema##*/}" in
        'installer.schema.json'|'*'*) ;;
        *)
          cd -- "${previous_wd}"
          PORT_PATH="${new_wd##*/libscript}"
          env -i PORT_PATH="${PORT_PATH}" \
                 PORT_PATH_WIN="$(printf '%s' "${PORT_PATH}" | tr '/' '\\')" \
                 "$(which envsubst)" < "${HTML_ROOT}"'/html/usage.html' >> "${html}"'.usage'
          sed 's/55//g' "${html}"'.usage' > "${html}"'.usage.tmp'
          mv -- "${html}"'.usage.tmp' "${html}"'.usage'
          # shellcheck disable=SC2016
          printf '${USAGE}' >> "${html}"
          wetzel -k '**MUST**' -- "${new_wd}"'/'"${json_schema}" | iconv -t utf-8  | pandoc -f markdown -t html5 | sed 's/<table>/<table class="tui-table hovered-purple striped-purple">/g' | iconv -f utf-8 >> "${html}"
          cd -- "${new_wd}"
          ;;
      esac
      # npm install -g wetzel
    fi
  done
  cd -- "${previous_wd}"
  cat -- "${HTML_ROOT}"'/html/bottom.html' >> "${html}"
  if [ -n "${LIBSCRIPT_DOCS_PREFIX}" ]; then
    h="${html#.}"
    urls_js="${urls_js}"'"'"${h#"${LIBSCRIPT_DOCS_PREFIX}"}"'",'
    urls="${urls}"' '"${html#"${LIBSCRIPT_DOCS_PREFIX}"}"
  else
    urls_js="${urls_js}"'"'"${html#.}"'",'
    urls="${urls}"' '"${html}"
  fi
done < "${find_res}"
rm -- "${find_res}"
urls_js="${urls_js%,}"']'
printf '%s\n' "${urls_js}"

for url in ${urls}; do
  title="${url##*/}"
  p="${url%/*}"
  p="${p##*/}"
  if [ "${title}" != 'README.html' ]; then
    title="${p}"'/'"${title}"
  fi
  if [ -n "${LIBSCRIPT_DOCS_PREFIX}" ]; then
    url="${LIBSCRIPT_DOCS_PREFIX}"'/'"${url}"
  fi
  USAGE=''
  previous_wd="$(pwd)"
  cd -- "${url%/*}"
  for f in *'.usage'; do
    case "${f}" in
      '*'*) ;;
      *)
        usage_="$(cat -- "${f}"; printf 'a')"
        usage_="${usage_%a}"
        USAGE="${USAGE}${usage_}"
        ;;
    esac
  done
  cd -- "${previous_wd}"
  env -i url="${url}" \
         TITLE='VerMan.io – '"${title%%.html}" \
         URLS="${urls_js}" \
         LIBSCRIPT_DOCS_DIR="${LIBSCRIPT_DOCS_DIR#.}" \
         LIBSCRIPT_ASSETS_DIR="${LIBSCRIPT_ASSETS_DIR}" \
         USAGE='${USAGE}' \
         "$(which envsubst)" < "${url}" > "${url}"'.tmp0'
  env -i USAGE="${USAGE}" \
         "$(which envsubst)" < "${url}"'.tmp0' > "${url}"'.tmp1'
  if [ "$(crc32 "${url}")" = "$(crc32 "${url}"'.tmp1')" ]; then
    rm -- "${url}"'.tmp1'
  else
    mv -- "${url}"'.tmp1' "${url}"
  fi
done

set -f
