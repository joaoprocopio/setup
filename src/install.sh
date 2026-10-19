#!/usr/bin/env bash

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tools"

usage() {
  cat <<'EOF'
uso: src/install.sh [passo...]

Sem argumentos, roda em ordem cada passo que ainda não deu certo e cada passo
que mudou desde a última vez que deu certo. Com argumentos, roda só os passos
citados, mesmo os que já deram certo. Cite um passo pelo nome (docker) ou pelo
arquivo (0040-docker).

  --list   mostra cada passo e o estado dele
  --help   mostra esta ajuda
EOF
}

die() {
  echo "$*" >&2
  exit 1
}

# A step is steps/NNNN-<name>.sh, plus an optional steps/NNNN-<name>/ that
# holds the files it installs. The number sets the order, and the name
# identifies the step everywhere else.
name_of() {
  echo "${1#*-}"
}

# A step's marker holds the hash of the step as it last succeeded, so
# editing its script or its files makes the next run pick it up again.
hash_of() {
  local dir="$SRC/steps/$1"
  if [ -d "$dir" ]; then
    {
      cat "$dir.sh"
      (cd "$dir" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 sha256sum)
    } | sha256sum | cut -d' ' -f1
  else
    sha256sum <"$dir.sh" | cut -d' ' -f1
  fi
}

state_of() {
  local marker
  marker="$STATE/$(name_of "$1").done"
  if [ ! -f "$marker" ]; then
    echo pendente
  elif [ "$(cat "$marker")" != "$(hash_of "$1")" ]; then
    echo mudou
  else
    echo feito
  fi
}

# Reads steps/ in order and refuses anything that breaks the layout, so a
# misnamed file is never skipped silently.
STEPS=()
declare -A seen_number seen_name
for f in "$SRC"/steps/*; do
  b="$(basename "$f")"
  if [ -d "$f" ]; then
    [ -f "$f.sh" ] || die "src/steps/$b/ não tem um src/steps/$b.sh"
    continue
  fi
  [[ "$b" =~ ^([0-9]{4})-([a-z0-9]+(-[a-z0-9]+)*)\.sh$ ]] ||
    die "src/steps/$b não segue o formato NNNN-nome.sh"
  number="${BASH_REMATCH[1]}"
  name="${BASH_REMATCH[2]}"
  [ -z "${seen_number[$number]:-}" ] || die "o número $number se repete: ${seen_number[$number]} e $b"
  [ -z "${seen_name[$name]:-}" ] || die "o nome $name se repete: ${seen_name[$name]} e $b"
  seen_number[$number]="$b"
  seen_name[$name]="$b"
  STEPS+=("${b%.sh}")
done

# Resolves a name or a NNNN-name to the step's NNNN-name.
resolve() {
  local s
  for s in "${STEPS[@]}"; do
    if [ "$s" = "$1" ] || [ "$(name_of "$s")" = "$1" ]; then
      echo "$s"
      return
    fi
  done
  die "passo desconhecido: $1"
}

case "${1:-}" in
  -h | --help)
    usage
    exit
    ;;
  --list)
    for s in "${STEPS[@]}"; do
      printf '%-20s %s\n' "$s" "$(state_of "$s")"
    done
    exit
    ;;
  -*)
    usage >&2
    exit 2
    ;;
esac

[ "$(id -u)" -ne 0 ] || die "rode como seu usuário, não como root: os passos chamam sudo quando precisam"

if [ $# -gt 0 ]; then
  run=()
  for arg in "$@"; do
    s="$(resolve "$arg")"
    run+=("$s")
  done
else
  run=()
  for s in "${STEPS[@]}"; do
    [ "$(state_of "$s")" = feito ] || run+=("$s")
  done
fi

if [ ${#run[@]} -eq 0 ]; then
  echo "nada a fazer: todos os passos já deram certo"
  exit
fi

# Asks for the password once and keeps sudo's timestamp fresh, so a long
# build never stops at a password prompt halfway through.
sudo -v
while kill -0 "$$" 2>/dev/null; do
  sudo -n -v 2>/dev/null || true
  sleep 60
done >/dev/null 2>&1 &
keepalive=$!

TOOLS_NOTES="$(mktemp)"
export TOOLS_NOTES
trap 'kill "$keepalive" 2>/dev/null; rm -f "$TOOLS_NOTES"' EXIT

mkdir -p "$STATE"
ok=()
failed=()
for s in "${run[@]}"; do
  name="$(name_of "$s")"
  printf '\n\033[1m==> %s\033[0m\n' "$name"
  if bash "$SRC/steps/$s.sh"; then
    hash_of "$s" >"$STATE/$name.done"
    ok+=("$name")
  else
    failed+=("$name")
  fi
done

echo
if [ ${#ok[@]} -gt 0 ]; then
  echo "deu certo: ${ok[*]}"
fi
if [ -s "$TOOLS_NOTES" ]; then
  echo
  echo "falta fazer à mão:"
  sed 's/^/  /' "$TOOLS_NOTES"
fi
if [ ${#failed[@]} -gt 0 ]; then
  echo >&2
  echo "falhou: ${failed[*]}" >&2
  echo "corrija e rode src/install.sh de novo: ele só roda o que ainda não deu certo." >&2
  exit 1
fi
