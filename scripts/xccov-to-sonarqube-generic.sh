#!/usr/bin/env bash
set -euo pipefail

function convert_xccov_to_xml {
  while IFS= read -r line; do
    if [[ $line =~ :$ ]]; then
      # Extract the file path and remove the trailing colon
      file_path="${line%:}"
      # Get just the last two components of the path
      relative_path=$(echo "$file_path" | rev | cut -d'/' -f1-2 | rev)
      echo "  <file path=\"$relative_path\">"
    elif [[ $line =~ ^[[:space:]]*([0-9]+):[[:space:]]*0 ]]; then
      echo "    <lineToCover lineNumber=\"${BASH_REMATCH[1]}\" covered=\"false\"/>"
    elif [[ $line =~ ^[[:space:]]*([0-9]+):[[:space:]]*[1-9] ]]; then
      echo "    <lineToCover lineNumber=\"${BASH_REMATCH[1]}\" covered=\"true\"/>"
    elif [[ -z $line ]]; then
      echo "  </file>"
    fi
  done
}

function xccov_to_generic {
  local xcresult="$1"

  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<coverage version="1">'
  xcrun xccov view --archive "$xcresult" | convert_xccov_to_xml
  echo '</coverage>'
}

function check_xcode_version() {
  local major=${1:-0} minor=${2:-0}
  return $(( (major >= 14) || (major == 13 && minor >= 3) ))
}

if ! xcode_version="$(xcodebuild -version | sed -n '1s/^Xcode \([0-9.]*\)$/\1/p')"; then
  echo 'Failed to get Xcode version' 1>&2
  exit 1
elif check_xcode_version ${xcode_version//./ }; then
  echo "Xcode version '$xcode_version' not supported, version 13.3 or above is required" 1>&2;
  exit 1
fi

xcresult="$1"
if [[ $# -ne 1 ]]; then
  echo "Invalid number of arguments. Expecting 1 path matching '*.xcresult'"
  exit 1
elif [[ ! -d $xcresult ]]; then
  echo "Path not found: $xcresult" 1>&2;
  exit 1
elif [[ $xcresult != *".xcresult"* ]]; then
  echo "Expecting input to match '*.xcresult', got: $xcresult" 1>&2;
  exit 1
fi

xccov_to_generic "$xcresult"
