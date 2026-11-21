#!/usr/bin/env bash

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SRC
readonly STEPS_DIR="$SRC/steps"
readonly IGNORE_FILE="${SRC%/*}/.setupignore"
# --admin records its runs machine-wide, so a --no-admin account can read them.
readonly ADMIN_STATE=/var/lib/tools
readonly HOME_STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tools"

MODE=
STEPS=()
declare -A IGNORED=()

usage() {
  cat <<'EOF'
usage: src/install.sh --admin|--no-admin [--list] [step...]

  --admin     install machine-wide software with sudo, then set up your home
  --no-admin  set up your home only, without sudo, after --admin installs the
              machine-wide part of each step that has one
  --list      print each step and its state
  --help      print this help

With no steps, runs each step that is pending or changed, and skips the steps
listed in .setupignore. With steps, runs those steps even when done or ignored.
Name a step as docker or 0040-docker.
EOF
}

die() {
  echo "$*" >&2
  exit 1
}

usage_error() {
  echo "$*" >&2
  usage >&2
  exit 2
}

# --- Steps

# Fills STEPS with every NNNN-name in order, and dies on a file that breaks that layout.
load_steps() {
  local path file number name
  local -A seen_numbers=() seen_names=()
  for path in "$STEPS_DIR"/*; do
    file="${path##*/}"
    if [ -d "$path" ]; then
      [ -f "$path.sh" ] || die "src/steps/$file/ has no src/steps/$file.sh"
      continue
    fi
    [[ $file =~ ^([0-9]{4})-([a-z0-9]+(-[a-z0-9]+)*)\.sh$ ]] ||
      die "src/steps/$file does not match NNNN-name.sh"
    number="${BASH_REMATCH[1]}"
    name="${BASH_REMATCH[2]}"
    [ -z "${seen_numbers[$number]:-}" ] || die "number $number repeats: ${seen_numbers[$number]} and $file"
    [ -z "${seen_names[$name]:-}" ] || die "name $name repeats: ${seen_names[$name]} and $file"
    seen_numbers[$number]="$file"
    seen_names[$name]="$file"
    STEPS+=("${file%.sh}")
  done
}

step_name() {
  echo "${1#*-}"
}

# usage: find_step <name-or-NNNN-name>
find_step() {
  local step
  for step in "${STEPS[@]}"; do
    if [ "$step" = "$1" ] || [ "$(step_name "$step")" = "$1" ]; then
      echo "$step"
      return
    fi
  done
  die "unknown step: $1"
}

# Fills IGNORED from .setupignore, one name or NNNN-name per line, and dies on an unknown step.
load_ignored() {
  local line number=0 step
  [ -f "$IGNORE_FILE" ] || return 0
  while IFS= read -r line || [ -n "$line" ]; do
    number=$((number + 1))
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    if [ -z "$line" ] || [ "${line:0:1}" = "#" ]; then continue; fi
    step="$(find_step "$line" 2>/dev/null)" || die "$IGNORE_FILE:$number: unknown step: $line"
    IGNORED[$step]=1
  done <"$IGNORE_FILE"
}

is_ignored() {
  [ -n "${IGNORED[$1]:-}" ]
}

# Hashes the script and its asset directory, so an edit to either reruns the step.
step_hash() {
  local script="$STEPS_DIR/$1.sh" assets="$STEPS_DIR/$1"
  {
    cat "$script"
    if [ -d "$assets" ]; then
      (cd "$assets" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum)
    fi
  } | sha256sum | cut -d' ' -f1
}

# --- State

# A marker holds the hash of the step version that last succeeded.
admin_marker() {
  echo "$ADMIN_STATE/$(step_name "$1").done"
}

home_marker() {
  echo "$HOME_STATE/$(step_name "$1").done"
}

own_marker() {
  if [ "$MODE" = admin ]; then admin_marker "$1"; else home_marker "$1"; fi
}

# usage: marker_state <marker> <hash>
marker_state() {
  if [ ! -f "$1" ]; then
    echo pending
  elif [ "$(cat "$1")" != "$2" ]; then
    echo changed
  else
    echo "done"
  fi
}

# A step that calls is_admin has a machine-wide part, which --admin installs before --no-admin can use it.
has_admin_part() {
  grep -qE '^[^#]*\bis_admin\b' "$STEPS_DIR/$1.sh"
}

# Prints done, pending, changed, or waiting, which means --admin has not run this version of a step with a machine-wide part.
step_state() {
  local hash
  hash="$(step_hash "$1")"
  if [ "$MODE" = no-admin ] && has_admin_part "$1" &&
    [ "$(marker_state "$(admin_marker "$1")" "$hash")" != "done" ]; then
    echo waiting
  else
    marker_state "$(own_marker "$1")" "$hash"
  fi
}

write_marker() {
  local marker hash
  marker="$(own_marker "$1")"
  hash="$(step_hash "$1")"
  if [ "$MODE" = admin ]; then
    echo "$hash" | sudo tee "$marker" >/dev/null
  else
    echo "$hash" >"$marker"
  fi
}

# --- Commands

list_steps() {
  local step state
  for step in "${STEPS[@]}"; do
    if is_ignored "$step"; then state=ignored; else state="$(step_state "$step")"; fi
    printf '%-20s %s\n' "$step" "$state"
  done
}

# Asks for the password once and refreshes it in the background, so a long build never stops at a prompt.
start_sudo() {
  sudo -v || die "--admin needs sudo"
  while kill -0 "$$" 2>/dev/null; do
    sudo -n -v 2>/dev/null || true
    sleep 60
  done >/dev/null 2>&1 &
  SUDO_KEEPALIVE=$!
  sudo install -d -m 0755 "$ADMIN_STATE"
}

# usage: run_steps <step>...
run_steps() {
  local step name passed=() failed=()

  SUDO_KEEPALIVE=
  TOOLS_NOTES="$(mktemp)"
  trap 'if [ -n "$SUDO_KEEPALIVE" ]; then kill "$SUDO_KEEPALIVE" 2>/dev/null; fi; rm -f "$TOOLS_NOTES"' EXIT
  export TOOLS_MODE="$MODE" TOOLS_NOTES

  if [ "$MODE" = admin ]; then start_sudo; fi
  mkdir -p "$HOME_STATE"

  for step in "$@"; do
    name="$(step_name "$step")"
    printf '\n\033[1m==> %s\033[0m\n' "$name"
    if [ "$MODE" = no-admin ] && [ "$(step_state "$step")" = waiting ]; then
      echo "$name: run src/install.sh --admin $name first" >&2
      failed+=("$name")
    elif bash "$STEPS_DIR/$step.sh" && write_marker "$step"; then
      passed+=("$name")
    else
      failed+=("$name")
    fi
  done

  echo
  if [ ${#passed[@]} -gt 0 ]; then
    echo "passed: ${passed[*]}"
  fi
  if [ -s "$TOOLS_NOTES" ]; then
    echo
    echo "to do by hand:"
    sed 's/^/  /' "$TOOLS_NOTES"
  fi
  if [ ${#failed[@]} -gt 0 ]; then
    echo >&2
    echo "failed: ${failed[*]}" >&2
    echo "fix them and run src/install.sh again: it runs only what has not passed." >&2
    exit 1
  fi
}

# --- Main

set_mode() {
  [ -z "$MODE" ] || usage_error "pass only one of --admin and --no-admin"
  MODE=$1
}

main() {
  local list=false names=() run=() name step

  while [ $# -gt 0 ]; do
    case $1 in
      --admin) set_mode admin ;;
      --no-admin) set_mode no-admin ;;
      --list) list=true ;;
      -h | --help)
        usage
        exit
        ;;
      -*) usage_error "unknown option: $1" ;;
      *) names+=("$1") ;;
    esac
    shift
  done
  [ -n "$MODE" ] || usage_error "pass --admin or --no-admin"
  readonly MODE

  load_steps
  load_ignored

  if $list; then
    list_steps
    exit
  fi

  [ "$(id -u)" -ne 0 ] || die "run as your own account, not as root"

  if [ ${#names[@]} -gt 0 ]; then
    for name in "${names[@]}"; do
      run+=("$(find_step "$name")")
    done
  else
    for step in "${STEPS[@]}"; do
      if is_ignored "$step"; then continue; fi
      [ "$(step_state "$step")" = "done" ] || run+=("$step")
    done
  fi

  if [ ${#run[@]} -eq 0 ]; then
    echo "nothing to do: every step has passed"
    exit
  fi

  run_steps "${run[@]}"
}

main "$@"
