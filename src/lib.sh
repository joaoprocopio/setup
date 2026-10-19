# Helpers shared by the scripts in steps/. A step sources this file first,
# which puts it in strict mode and lets it also run on its own:
#
#   src/steps/0040-docker.sh

set -euo pipefail

# The name drops the order prefix, so renumbering a step keeps its
# rc_block markers and its done marker.
STEP="$(basename "$0" .sh)"
STEP="${STEP#[0-9][0-9][0-9][0-9]-}"
# Files a step installs live in a directory named after its script, such as
# steps/0130-claude/ next to steps/0130-claude.sh.
ASSETS="$(cd "$(dirname "$0")" && pwd)/$(basename "$0" .sh)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"

# Installers that find ~/.local/bin on PATH leave the shell profiles alone,
# and a step can call what an earlier step put there.
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Scratch space, removed when the step exits. It lives in /var/tmp because
# /tmp is a RAM-backed tmpfs on Debian 13 and builds fill it fast. It is
# world-readable because apt reads local .deb files as the _apt user.
WORK="$(mktemp -d -p /var/tmp tools.XXXXXX)"
chmod 755 "$WORK"
trap 'rm -rf "$WORK"' EXIT

# The first install in a step refreshes the package index, so a step run on
# its own long after base still finds current packages.
apt_install() {
  if [ -z "${APT_FRESH:-}" ]; then
    sudo apt-get update
    APT_FRESH=1
  fi
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install --yes "$@"
}

# Installs the .deb at <url>. apt resolves its dependencies, unlike dpkg -i.
# usage: deb_install <name> <url>
deb_install() {
  curl -#fSL "$2" -o "$WORK/$1.deb"
  apt_install "$WORK/$1.deb"
}

# Adds an apt repository and refreshes the package index. <name> picks the
# files it writes, so running it again overwrites them:
# /etc/apt/keyrings/<name>.{asc,gpg} and /etc/apt/sources.list.d/<name>.sources.
# It also deletes <name>.list, because apt refuses a repository that two
# files declare with different Signed-By values.
# usage: apt_source <name> <key-url> <uri> <suite> [components]
apt_source() {
  local name=$1 key_url=$2 uri=$3 suite=$4 components=${5:-} keyring

  curl -fsSL "$key_url" -o "$WORK/$name.key"
  # apt tells an armored key from a binary one by the file extension.
  if grep -q -- '-----BEGIN PGP' "$WORK/$name.key"; then
    keyring="/etc/apt/keyrings/$name.asc"
  else
    keyring="/etc/apt/keyrings/$name.gpg"
  fi
  sudo install -D -m 0644 "$WORK/$name.key" "$keyring"

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
  APT_FRESH=1
}

# Writes stdin to <file> between two marker lines named after the step. A
# second run replaces the block in place, so it never piles up duplicates.
# usage: rc_block <file> <<'EOF' ... EOF
rc_block() {
  local file=$1
  touch "$file"
  RC_BEGIN="# >>> tools: $STEP >>>" RC_END="# <<< tools: $STEP <<<" RC_BODY="$(cat)" awk '
    $0 == ENVIRON["RC_BEGIN"] { print; print ENVIRON["RC_BODY"]; skip = found = 1; next }
    $0 == ENVIRON["RC_END"] { skip = 0 }
    !skip
    END { if (!found) printf "\n%s\n%s\n%s\n", ENVIRON["RC_BEGIN"], ENVIRON["RC_BODY"], ENVIRON["RC_END"] }
  ' "$file" >"$WORK/rc"
  # Writing through the existing file keeps a symlinked rc file a symlink.
  cat "$WORK/rc" >"$file"
}

# Queues a follow-up that needs you, such as a login or a relogin.
# install.sh prints the queue after the last step.
note() {
  printf '%s: %s\n' "$STEP" "$*" >>"${TOOLS_NOTES:-/dev/stderr}"
}
