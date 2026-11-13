#!/bin/bash
# Resolve YOUVERSION_APP_KEY for local xcodebuild invocations.
# Source this file from the repo root (the directory that contains Config/).
# On success, YOUVERSION_XCODE_ARGS is set. The environment value, when
# present, is passed through as a build setting. Otherwise Config/Local.xcconfig
# supplies it and YOUVERSION_XCODE_ARGS stays empty.
# This script never prints the key.

youversion_trim() {
  printf '%s' "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

youversion_prepare_xcode_args() {
  YOUVERSION_XCODE_ARGS=()
  local env_key
  env_key=$(youversion_trim "${YOUVERSION_APP_KEY:-}")
  if [ -n "$env_key" ]; then
    YOUVERSION_XCODE_ARGS=("YOUVERSION_APP_KEY=${env_key}")
    return 0
  fi

  local file="Config/Local.xcconfig"
  if [ ! -f "$file" ]; then
    return 1
  fi

  local line value
  line=$(grep -E '^[[:space:]]*YOUVERSION_APP_KEY[[:space:]]*=' "$file" | tail -n 1 || true)
  if [ -z "$line" ]; then
    return 1
  fi
  value=${line#*=}
  value=${value%%//*}
  value=$(youversion_trim "$value")
  case "$value" in
    \"*\")
      value=${value#\"}
      value=${value%\"}
      value=$(youversion_trim "$value")
      ;;
  esac
  if [ -z "$value" ]; then
    return 1
  fi
  return 0
}
