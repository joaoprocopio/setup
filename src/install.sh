#!/usr/bin/env bash

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
. "$SRC/profile.sh"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tools"
# The system part of a step is machine-wide, so its marker is too.
SYSTEM_STATE=/var/lib/tools

usage() {
  cat <<'EOF'
uso: src/install.sh [passo...]

Roda nas duas contas da máquina, e a conta admin roda primeiro:
  admin    está no grupo sudo. Instala o que é da máquina inteira (apt, /etc,
           /usr/local, serviços) e também configura a própria home.
  sem sudo configura só a própria home, em cima do que a conta admin instalou.
           Nunca chama sudo. Um passo cuja parte de sistema a conta admin ainda
           não rodou nesta versão falha, e mostra "espera o admin" no --list.

Na primeira vez a conta escolhe o perfil (pessoal ou trabalho) e a identidade
do git, que ficam em ~/.config/tools/profile. Um passo marcado com
"# profile: pessoal" só roda nesse perfil.

Sem argumentos, roda em ordem cada passo do perfil que ainda não deu certo e
cada passo que mudou desde a última vez que deu certo. Com argumentos, roda só
os passos citados, mesmo os que já deram certo. Cite um passo pelo nome
(docker) ou pelo arquivo (0040-docker).

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

# A step defines system() for what touches the machine and user() for what
# stays under $HOME, each on a line of its own, and may define both.
has_part() {
  grep -Fxq "$2() {" "$SRC/steps/$1.sh"
}

# A step marked "# profile: X" runs only in profile X. With no profile
# loaded yet, nothing is filtered.
profile_of() {
  sed -n '/^# profile: /{s///p;q;}' "$SRC/steps/$1.sh"
}

out_of_profile() {
  local p
  p="$(profile_of "$1")"
  [ -n "$p" ] && [ -n "${PROFILE:-}" ] && [ "$p" != "$PROFILE" ]
}

# usage: marker_state <marker> <step>
marker_state() {
  if [ ! -f "$1" ]; then
    echo pendente
  elif [ "$(cat "$1")" != "$(hash_of "$2")" ]; then
    echo mudou
  else
    echo feito
  fi
}

state_of() {
  local name part
  name="$(name_of "$1")"
  if out_of_profile "$1"; then
    echo "fora do perfil"
    return
  fi
  if has_part "$1" system; then
    part="$(marker_state "$SYSTEM_STATE/$name.done" "$1")"
    if [ "$part" != feito ]; then
      if [ -n "$ADMIN" ]; then echo "$part"; else echo "espera o admin"; fi
      return
    fi
  fi
  if has_part "$1" user; then
    part="$(marker_state "$STATE/$name.done" "$1")"
    if [ "$part" != feito ]; then
      echo "$part"
      return
    fi
  fi
  echo feito
}

# Runs the parts of one step. Inside an if, set -e is off, so every failure
# returns on purpose.
run_one() {
  local s=$1 name hash
  name="$(name_of "$s")"
  hash="$(hash_of "$s")"
  if has_part "$s" system; then
    if [ -n "$ADMIN" ]; then
      if [ -n "$explicit" ] || [ "$(marker_state "$SYSTEM_STATE/$name.done" "$s")" != feito ]; then
        bash "$SRC/steps/$s.sh" system || return 1
        sudo install -d -m 0755 "$SYSTEM_STATE" || return 1
        echo "$hash" | sudo tee "$SYSTEM_STATE/$name.done" >/dev/null || return 1
        sudo chmod 0644 "$SYSTEM_STATE/$name.done" || return 1
      fi
    elif [ "$(marker_state "$SYSTEM_STATE/$name.done" "$s")" != feito ]; then
      echo "$name: a parte de sistema deste passo não rodou nesta versão; rode src/install.sh na conta admin primeiro" >&2
      return 1
    fi
  fi
  if has_part "$s" user; then
    if [ -n "$explicit" ] || [ "$(marker_state "$STATE/$name.done" "$s")" != feito ]; then
      bash "$SRC/steps/$s.sh" user || return 1
      echo "$hash" >"$STATE/$name.done" || return 1
    fi
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
  has_part "${b%.sh}" system || has_part "${b%.sh}" user ||
    die "src/steps/$b não define system() nem user()"
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

# First run in this account: asks which profile it is and who commits from it.
# The answers go to the profile file, which stays out of the repository.
if [ ! -f "$PROFILE_FILE" ]; then
  ask() {
    local answer
    printf '%s ' "$1" >&2
    read -r answer || die "sem resposta para: $1"
    echo "$answer"
  }
  PROFILE=
  while [ "$PROFILE" != pessoal ] && [ "$PROFILE" != trabalho ]; do
    PROFILE="$(ask 'perfil desta conta (pessoal ou trabalho):')"
  done
  GIT_NAME=
  while [ -z "$GIT_NAME" ]; do
    GIT_NAME="$(ask 'nome no git:')"
  done
  GIT_EMAIL=
  while [ -z "$GIT_EMAIL" ]; do
    GIT_EMAIL="$(ask 'email no git:')"
  done
  mkdir -p "$(dirname "$PROFILE_FILE")"
  {
    printf '%s=%q\n' PROFILE "$PROFILE"
    printf '%s=%q\n' GIT_NAME "$GIT_NAME"
    printf '%s=%q\n' GIT_EMAIL "$GIT_EMAIL"
  } >"$PROFILE_FILE"
  # shellcheck source=/dev/null
  . "$PROFILE_FILE"
fi

explicit=
if [ $# -gt 0 ]; then
  explicit=1
  run=()
  for arg in "$@"; do
    s="$(resolve "$arg")"
    if out_of_profile "$s"; then
      die "o passo $(name_of "$s") é do perfil $(profile_of "$s"), e esta conta é do perfil $PROFILE"
    fi
    run+=("$s")
  done
else
  run=()
  for s in "${STEPS[@]}"; do
    if out_of_profile "$s"; then continue; fi
    [ "$(state_of "$s")" = feito ] || run+=("$s")
  done
fi

if [ ${#run[@]} -eq 0 ]; then
  echo "nada a fazer: todos os passos já deram certo"
  exit
fi

# Only the admin account has sudo. It asks for the password once and keeps
# sudo's timestamp fresh, so a long build never stops at a password prompt
# halfway through.
keepalive=
if [ -n "$ADMIN" ]; then
  sudo -v
  while kill -0 "$$" 2>/dev/null; do
    sudo -n -v 2>/dev/null || true
    sleep 60
  done >/dev/null 2>&1 &
  keepalive=$!
fi

TOOLS_NOTES="$(mktemp)"
export TOOLS_NOTES
trap 'if [ -n "$keepalive" ]; then kill "$keepalive" 2>/dev/null; fi; rm -f "$TOOLS_NOTES"' EXIT

mkdir -p "$STATE"
ok=()
failed=()
for s in "${run[@]}"; do
  name="$(name_of "$s")"
  printf '\n\033[1m==> %s\033[0m\n' "$name"
  if run_one "$s"; then
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
