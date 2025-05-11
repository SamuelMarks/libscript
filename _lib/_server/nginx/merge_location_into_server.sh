#!/bin/sh

set -feu
# shellcheck disable=SC2296,SC3028,SC3040,SC3054
if [ "${SCRIPT_NAME-}" ]; then
  this_file="${SCRIPT_NAME}"
elif [ "${BASH_SOURCE-}" ]; then
  this_file="${BASH_SOURCE[0]}"
  set -o pipefail
elif [ "${ZSH_VERSION-}" ]; then
  this_file="${(%):-%x}"
  set -o pipefail
else
  this_file="${0}"
fi

case "${STACK+x}" in
  *':'"${this_file}"':'*)
    printf '[STOP]     processing "%s"\n' "${this_file}"
    if (return 0 2>/dev/null); then return; else exit 0; fi ;;
  *) printf '[CONTINUE] processing "%s"\n' "${this_file}" ;;
esac
export STACK="${STACK:-}${this_file}"':'

merge_location_into_server() {
  EXISTING_CONFIG="$1"
  NEW_LOCATION_BLOCK="$2"
  TARGET_SERVER_NAME="$3"

  # Read existing config content
  if [ -f "$EXISTING_CONFIG" ]; then
    CONFIG_FILE="$EXISTING_CONFIG"
  else
    CONFIG_FILE=$(mktemp)
    trap 'rm -f -- "${CONFIG_FILE}"' EXIT HUP INT QUIT TERM
    printf '%s' "$EXISTING_CONFIG" > "$CONFIG_FILE"
  fi

  # Read new location block content
  if [ -f "$NEW_LOCATION_BLOCK" ]; then
    NEW_LOCATION_BLOCK_CONTENT=$(cat "$NEW_LOCATION_BLOCK")
  else
    NEW_LOCATION_BLOCK_CONTENT="$NEW_LOCATION_BLOCK"
  fi

  OUTPUT_FILE=$(mktemp)
  trap 'rm -f -- "${OUTPUT_FILE}"' EXIT HUP INT QUIT TERM


  in_server_block=0
  brace_level=0
  server_has_server_name=0
  server_has_listen_ssl=0
  insert_done=0

  SERVER_BLOCK_TMP=$(mktemp)
  SERVER_LOCATIONS_TMP=$(mktemp)
  trap 'rm -f -- "${SERVER_BLOCK_TMP}" "${SERVER_LOCATIONS_TMP}"' EXIT HUP INT QUIT TERM

  while IFS= read -r line || [ -n "$line" ]; do
    trimmed_line=$(printf '%s' "$line" | sed 's/^[ \t]*//;s/[ \t]*$//')

    # Update brace level before any other processing
    num_open_braces=$(printf '%s' "$line" | grep -o '{' | wc -l)
    num_close_braces=$(printf '%s' "$line" | grep -o '}' | wc -l)
    brace_level=$((brace_level + num_open_braces - num_close_braces))

    if [ "$in_server_block" -eq 0 ]; then
      # Check for start of server block
      if printf '%s' "$trimmed_line" | grep -q '^server\b'; then
        in_server_block=1
        server_has_server_name=0
        server_has_listen_ssl=0

        # Initialize server block content and locations
        printf '%s\n' "$line" > "$SERVER_BLOCK_TMP"
        : > "$SERVER_LOCATIONS_TMP"  # Empty the locations file
        continue
      else
        # Outside of server block, output line directly
        printf '%s\n' "$line" >> "$OUTPUT_FILE"
        continue
      fi
    else
      # Accumulate server block content
      printf '%s\n' "$line" >> "$SERVER_BLOCK_TMP"

      # Check for server_name
      if printf '%s' "$trimmed_line" | grep -q '^server_name[ \t]'; then
        server_names=$(printf '%s' "$trimmed_line" | sed 's/^server_name[ \t]*//;s/;.*$//')
        for name in $server_names; do
          if [ "$name" = "$TARGET_SERVER_NAME" ]; then
            server_has_server_name=1
            break
          fi
        done
      fi

      # Check for listen 443 ssl
      if printf '%s' "$trimmed_line" | grep -q '^listen[ \t].*443.*ssl'; then
        server_has_listen_ssl=1
      fi

      # Collect existing location expressions in the server block
      if printf '%s' "$trimmed_line" | grep -q '^location[ \t]'; then
        # Extract the location expression up to '{' or ';'
        location_expression=$(printf '%s' "$trimmed_line" | sed -E 's/^(location[ \t]+[^ \t{;]+([ \t]+[^ \t{;]+)*)[ \t]*[;{]?.*/\1/')
        printf '%s\n' "$location_expression" >> "$SERVER_LOCATIONS_TMP"
      fi

      # Exiting server block
      if [ "$brace_level" -le 0 ]; then
        in_server_block=0

        # If this is the matching server block, insert the new location block
        if [ "$server_has_server_name" -eq 1 ] && \
           [ "$server_has_listen_ssl" -eq 1 ] && \
           [ "$insert_done" -eq 0 ]; then

          # Process the server block content
          # Remove the last closing brace '}' from the server block content
          sed '$d' "$SERVER_BLOCK_TMP" > "${SERVER_BLOCK_TMP}.processed"

          # Get indentation from the closing brace line
          closing_brace_line=$(tail -n 1 "$SERVER_BLOCK_TMP")
          indentation=$(printf '%s' "$closing_brace_line" | sed 's/\(^[ \t]*\).*/\1/')

          # Prepare the new location blocks, excluding duplicates
          NEW_LOCATION_BLOCK_TMP=$(mktemp)
          trap 'rm -f -- "${NEW_LOCATION_BLOCK_TMP}"' EXIT HUP INT QUIT TERM
          printf '%s\n' "$NEW_LOCATION_BLOCK_CONTENT" > "$NEW_LOCATION_BLOCK_TMP"

          # Collect location expressions from new location block
          NEW_LOCATIONS_TMP=$(mktemp)
          trap 'rm -f -- "${NEW_LOCATIONS_TMP}"' EXIT HUP INT QUIT TERM
          sed -n -E 's/^[ \t]*(location[ \t]+[^ \t{;]+([ \t]+[^ \t{;]+)*)[ \t]*[;{]?.*/\1/p' "$NEW_LOCATION_BLOCK_TMP" > "$NEW_LOCATIONS_TMP"

          # Exclude duplicate location blocks
          INSERT_BLOCK_TMP=$(mktemp)
          trap 'rm -f -- "${INSERT_BLOCK_TMP}"' EXIT HUP INT QUIT TERM
          awk -- 'FNR==NR {existing[$0]=1; next} {if ($0 in existing) {print "duplicate:" $0} else {print "new:" $0}}' "$SERVER_LOCATIONS_TMP" "$NEW_LOCATIONS_TMP" | while IFS=: read -r status loc_expr; do
            if [ "${status}" = "duplicate" ]; then
              # Location already exists, skip it
              >&2 printf 'Debug: Skipping duplicate location "%s"\n' "${loc_expr}"
              continue
            else
              # Include this location block
              # Extract the corresponding block from NEW_LOCATION_BLOCK_TMP
              awk -v loc_expr="${loc_expr}" -- '
                BEGIN {found=0}
                $0 ~ "^[ \t]*"loc_expr"[ \t]*([;{]|$)" {found=1}
                found {print}
                found && /\}/ {found=0}' "${NEW_LOCATION_BLOCK_TMP}" >> "${INSERT_BLOCK_TMP}"
            fi
          done

          # Append new location blocks with proper indentation
          if [ -s "${INSERT_BLOCK_TMP}" ]; then
            printf '\n' >> "${SERVER_BLOCK_TMP}"'.processed'
            sed 's/^/'"${indentation}"'/' "${INSERT_BLOCK_TMP}" >> "${SERVER_BLOCK_TMP}"'.processed'
          fi

          # Add the closing brace back
          printf '%s\n' "$closing_brace_line" >> "${SERVER_BLOCK_TMP}.processed"

          # Output the processed server block
          cat -- "${SERVER_BLOCK_TMP}.processed" >> "${OUTPUT_FILE}"

          insert_done=1

          # Clean up temporary files
          rm -f -- "${SERVER_BLOCK_TMP}" "${SERVER_BLOCK_TMP}"'.processed' "${SERVER_LOCATIONS_TMP}" "${NEW_LOCATION_BLOCK_TMP}" "${NEW_LOCATIONS_TMP}" "${INSERT_BLOCK_TMP}"
        else
          # Output the server block as is
          cat -- "${SERVER_BLOCK_TMP}" >> "${OUTPUT_FILE}"
        fi
      fi
    fi
  done < "${CONFIG_FILE}"

  # Check if insertion was done
  if [ "${insert_done}" -eq 0 ]; then
    >&2 printf 'Error: No matching server block found.\n'
    exit 1
  else
    # Output the final configuration
    cat -- "${OUTPUT_FILE}"
  fi
}
