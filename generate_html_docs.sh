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
set -eu

LIBSCRIPT_ROOT_DIR="${LIBSCRIPT_ROOT_DIR:-$( CDPATH='' cd -- "$( dirname -- "$( readlink -nf -- "${this_file}" )")" && pwd)}"
export LIBSCRIPT_ROOT_DIR

LIBSCRIPT_DOCS_DIR="${LIBSCRIPT_DOCS_DIR:-./docs}"
export LIBSCRIPT_DOCS_DIR

HTML_ROOT="${HTML_ROOT:-$LIBSCRIPT_ROOT_DIR}"
export HTML_ROOT

[ -d "${LIBSCRIPT_DOCS_DIR}" ] || mkdir -p "${LIBSCRIPT_DOCS_DIR}"
cp 'tuicss.min.css' "${LIBSCRIPT_DOCS_DIR}"'/'
cp 'tuicss.min.js' "${LIBSCRIPT_DOCS_DIR}"'/'
cp 'styles.css' "${LIBSCRIPT_DOCS_DIR}"'/'
urls_js='['
urls=''
for f in $(find -s "${LIBSCRIPT_ROOT_DIR}" -type f -name '*.md'); do
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
        [ -d "${parent}" ] || mkdir -p "${parent}"
      fi
      ;;
    *'/'*)
      [ -d "${parent}" ] || mkdir -p "${parent}"
      ;;
  esac
  # npm install -g @adobe/jsonschema2md

  html="${out%%.md}"'.html'

  cp "${HTML_ROOT}"'/top.html' "${html}"
  iconv -t utf-8 "${f}" | sed 's/.md)/.html)/g' | pandoc -f markdown -t html5 | iconv -f utf-8 >> "${html}"
  json_schema="${out%%.md}"'.schema.json'
  if [ -f "${json_schema}" ]; then
    true  # TODO
  fi
  cat -- "${HTML_ROOT}"'/bottom.html' >> "${html}"
  urls_js="${urls_js}"'"'"${html#.}"'",'
  urls="${urls}"' '"${html}"
done
urls_js="${urls_js%,}"']'
printf '%s\n' "${urls_js}"

#tmp_script="$(mktemp)"
SCRIPT_NAME="${LIBSCRIPT_ROOT_DIR}"'/_lib/_common/envsubst_safe.sh'
#printf '#!/bin/sh\n export SCRIPT_NAME ; . "%s" ; envsubst_safe' "${SCRIPT_NAME}" > "${tmp_script}"
#chmod +x "${tmp_script}"
export SCRIPT_NAME
# shellcheck disable=SC1090
. "${SCRIPT_NAME}"
for url in ${urls}; do
  # env -i tmp_script="${tmp_script}" url="${url}" REPLACE_THIS="${urls_js}" "${tmp_script}" < "${url}" > "${url}"'.tmp'
  REPLACE_THIS="${urls_js}"
  export REPLACE_THIS
  envsubst < "${url}" > "${url}"'.tmp'
  mv "${url}"'.tmp' "${url}"
done
#rm -- "${tmp_script}"
##for d in "${LIBSCRIPT_ROOT_DIR}"'/_lib/'*; do
 # echo "${d%LIBSCRIPT_ROOT_DIR}"
#done
#find . -type f -name '*.md' | xargs -n1 pandoc -f markdown -t html5