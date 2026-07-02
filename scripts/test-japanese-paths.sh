#!/usr/bin/env bash
set -Eeuo pipefail

export LANG="${LANG:-C.UTF-8}"
export LC_ALL="${LC_ALL:-C.UTF-8}"

TEST_ROOT="${OPENFOAM_JAPANESE_TEST_ROOT:-/tmp/openfoam-japanese-paths}"

log() {
  printf '\n[%s] %s\n' "$(date -u +%H:%M:%S)" "$*"
}

fail() {
  printf '\nERROR: %s\n' "$*" >&2
  exit 1
}

load_openfoam() {
  # Support both OpenFOAM Foundation and OpenCFD-style images/installations.
  if command -v blockMesh >/dev/null 2>&1 && command -v foamDictionary >/dev/null 2>&1; then
    return 0
  fi

  local candidates=(
    /opt/openfoam*/etc/bashrc
    /usr/lib/openfoam*/etc/bashrc
    /usr/lib/openfoam/openfoam*/etc/bashrc
    /openfoam/etc/bashrc
  )

  local bashrc
  for bashrc in "${candidates[@]}"; do
    # shellcheck disable=SC1090
    if [[ -f "$bashrc" ]]; then
      source "$bashrc"
      break
    fi
  done

  command -v blockMesh >/dev/null 2>&1 || fail "blockMesh not found after sourcing OpenFOAM environment"
  command -v foamDictionary >/dev/null 2>&1 || fail "foamDictionary not found after sourcing OpenFOAM environment"
}

find_source_case() {
  local candidates=(
    "${FOAM_TUTORIALS:-}/incompressible/icoFoam/cavity/cavity"
    "${FOAM_TUTORIALS:-}/incompressibleFluid/cavity/cavity"
    /opt/openfoam*/tutorials/incompressible/icoFoam/cavity/cavity
    /opt/openfoam*/tutorials/incompressibleFluid/cavity/cavity
    /usr/lib/openfoam*/tutorials/incompressible/icoFoam/cavity/cavity
    /usr/lib/openfoam*/tutorials/incompressibleFluid/cavity/cavity
  )

  local case_dir
  for case_dir in "${candidates[@]}"; do
    if [[ -d "$case_dir/system" && -d "$case_dir/constant" ]]; then
      printf '%s\n' "$case_dir"
      return 0
    fi
  done

  return 1
}

copy_case() {
  local src=$1
  local dst=$2
  mkdir -p "$(dirname "$dst")"
  rm -rf "$dst"
  cp -a "$src" "$dst"
}

run_case() {
  local case_dir=$1
  log "Testing OpenFOAM case path: $case_dir"

  blockMesh -case "$case_dir" >"$case_dir/log.blockMesh" 2>&1
  foamDictionary -case "$case_dir" system/controlDict -entry application -value \
    >"$case_dir/log.foamDictionary" 2>&1

  local solver
  solver=$(foamDictionary -case "$case_dir" system/controlDict -entry application -value)
  command -v "$solver" >/dev/null 2>&1 || fail "Configured solver '$solver' is not available"
  "$solver" -case "$case_dir" >"$case_dir/log.$solver" 2>&1

  test -s "$case_dir/log.blockMesh"
  test -s "$case_dir/log.foamDictionary"
  test -s "$case_dir/log.$solver"
  log "OK: $case_dir"
}

main() {
  log "Locale: LANG=$LANG LC_ALL=$LC_ALL"
  load_openfoam
  log "OpenFOAM loaded: WM_PROJECT=${WM_PROJECT:-unknown} WM_PROJECT_VERSION=${WM_PROJECT_VERSION:-unknown}"

  local src_case
  src_case=$(find_source_case) || fail "Could not locate the cavity tutorial case"
  log "Template case: $src_case"

  rm -rf "$TEST_ROOT"

  local cases=(
    "$TEST_ROOT/of_ascii/case01"
    "$TEST_ROOT/日本語/case01"
    "$TEST_ROOT/foam/ケース001"
    "$TEST_ROOT/顧客A/解析/case01"
    "$TEST_ROOT/顧客A/解析 ケース01"
    "$TEST_ROOT/日本語 パス/ケース 001"
    "$TEST_ROOT/顧客 A/解析 ケース 01"
  )

  local case_dir
  for case_dir in "${cases[@]}"; do
    copy_case "$src_case" "$case_dir"
    run_case "$case_dir"
  done

  log "All Japanese/Unicode path smoke tests passed. Results are under $TEST_ROOT"
}

main "$@"
