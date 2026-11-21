# Sourced first by every step in src/steps/.

set -euo pipefail

# --- Mode

case "${TOOLS_MODE:-}" in
  admin | no-admin) ;;
  *)
    echo "run steps through src/install.sh --admin or --no-admin" >&2
    exit 2
    ;;
esac

is_admin() {
  [ "$TOOLS_MODE" = admin ]
}

# A --no-admin run fails on sudo instead of prompting for a password it cannot have.
if ! is_admin; then
  sudo() {
    echo "$STEP: sudo $* needs --admin" >&2
    return 1
  }
fi

# --- Context

# The name drops the NNNN- prefix, so renumbering a step keeps its rc_block markers.
STEP="$(basename "$0" .sh)"
STEP="${STEP#[0-9][0-9][0-9][0-9]-}"
# shellcheck disable=SC2034 # Steps read ASSETS.
ASSETS="$(cd "$(dirname "$0")" && pwd)/$(basename "$0" .sh)"
# shellcheck disable=SC2034 source=/dev/null # Steps read CODENAME.
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

# Installers that find ~/.local/bin on PATH leave the shell profiles alone.
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# usage: needs <step> [command], and exits naming <step> when the command it installs is missing.
needs() {
  local step=$1 command=${2:-$1}
  command -v "$command" >/dev/null && return
  echo "$STEP: needs $command from the $step step; run src/install.sh --$TOOLS_MODE $step, or remove $step from .setupignore" >&2
  exit 1
}

# /var/tmp because /tmp is a small tmpfs on Debian 13, and 755 because apt reads local .debs as _apt.
WORK="$(mktemp -d -p /var/tmp tools.XXXXXX)"
chmod 755 "$WORK"
trap 'rm -rf "$WORK"' EXIT

# --- apt (admin only)

# usage: apt_install <package-or-deb-path>...
apt_install() {
  if [ -z "${APT_UPDATED:-}" ]; then
    sudo apt-get update
    APT_UPDATED=1
  fi
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install --yes "$@"
}

# usage: deb_install <name> <url>
deb_install() {
  curl -#fSL "$2" -o "$WORK/$1.deb"
  apt_install "$WORK/$1.deb"
}

# usage: apt_source <name> <key-url> <uri> <suite> [components]
apt_source() {
  local name=$1 key_url=$2 uri=$3 suite=$4 components=${5:-} keyring

  curl -fsSL "$key_url" -o "$WORK/$name.key"
  # apt tells an armored key from a binary one by the extension.
  if grep -q -- '-----BEGIN PGP' "$WORK/$name.key"; then
    keyring="/etc/apt/keyrings/$name.asc"
  else
    keyring="/etc/apt/keyrings/$name.gpg"
  fi
  sudo install -D -m 0644 "$WORK/$name.key" "$keyring"

  # apt refuses a repository that two files declare with different Signed-By values.
  sudo rm -f "/etc/apt/sources.list.d/$name.list"
  {
    echo "Types: deb"
    echo "URIs: $uri"
    echo "Suites: $suite"
    if [ -n "$components" ]; then echo "Components: $components"; fi
    echo "Architectures: $(dpkg --print-architecture)"
    echo "Signed-By: $keyring"
  } | sudo tee "/etc/apt/sources.list.d/$name.sources" >/dev/null

  sudo apt-get update
  APT_UPDATED=1
}

# --- Home

# Writes stdin between marker lines named after the step, replacing that block on a rerun: rc_block <file> <<'EOF'
rc_block() {
  local file=$1
  touch "$file"
  RC_BEGIN="# >>> tools: $STEP >>>" RC_END="# <<< tools: $STEP <<<" RC_BODY="$(cat)" awk '
    $0 == ENVIRON["RC_BEGIN"] { print; print ENVIRON["RC_BODY"]; skip = found = 1; next }
    $0 == ENVIRON["RC_END"] { skip = 0 }
    !skip
    END { if (!found) printf "\n%s\n%s\n%s\n", ENVIRON["RC_BEGIN"], ENVIRON["RC_BODY"], ENVIRON["RC_END"] }
  ' "$file" >"$WORK/rc"
  # cat keeps a symlinked rc file a symlink.
  cat "$WORK/rc" >"$file"
}

# Queues a manual follow-up, which install.sh prints after the last step.
note() {
  printf '%s: %s\n' "$STEP" "$*" >>"${TOOLS_NOTES:-/dev/stderr}"
}
