#!/usr/bin/env bash
# Runs src/install.sh as an admin account and as a no-sudo account, and exits 1 if any assertion fails.
# usage: docker run --rm -v "$PWD:/repo:ro" debian:trixie bash /repo/test/two-accounts.sh

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO
# Only steps that run in a container without systemd, a desktop, or a kernel module.
readonly STEPS="terminal git go yq gitleaks"
readonly SUDO_LOG=/tmp/sudo.log

if [ "$(id -u)" -ne 0 ] || { [ ! -f /.dockerenv ] && [ ! -f /run/.containerenv ]; }; then
  echo "run this as root in a throwaway container, because it adds accounts and a sudoers file" >&2
  exit 2
fi

# --- Setup

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install --yes -qq sudo curl ca-certificates >/dev/null

useradd --create-home --shell /bin/bash admin
useradd --create-home --shell /bin/bash work
echo 'admin ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/admin

# Without .git, because a worktree's .git file points to a path outside the container, and git then refuses to run.
for account in admin work; do
  mkdir "/home/$account/setup"
  tar -C "$REPO" --exclude=./.git -cf - . | tar -C "/home/$account/setup" -xf -
  chown -R "$account:" "/home/$account/setup"
done

# A sudo that logs each call and fails, first on the work account's PATH.
mkdir -p /opt/fake-sudo
cat >/opt/fake-sudo/sudo <<EOF
#!/bin/sh
echo "sudo \$*" >>$SUDO_LOG
exit 1
EOF
chmod 755 /opt/fake-sudo/sudo
: >"$SUDO_LOG"
chmod 666 "$SUDO_LOG"

# --- Assertions

OUT="$(mktemp)"
RC=0
FAILURES=0

# usage: as <account> <command>, run in that account's clone, with the output in OUT and the exit code in RC
as() {
  local account=$1 path=
  shift
  if [ "$account" = work ]; then path="export PATH=/opt/fake-sudo:\$PATH; "; fi
  RC=0
  su - "$account" -c "${path}cd ~/setup && $*" >"$OUT" 2>&1 || RC=$?
}

pass() {
  echo "ok   $1"
}

fail() {
  echo "FAIL $1"
  tail -n 30 "$OUT" | sed 's/^/     | /'
  FAILURES=$((FAILURES + 1))
}

# usage: expect_exit <code> <description>
expect_exit() {
  if [ "$RC" -eq "$1" ]; then pass "$2"; else fail "$2: exit $RC, want $1"; fi
}

# usage: expect_output <extended-regex> <description>
expect_output() {
  if grep -qE -- "$1" "$OUT"; then pass "$2"; else fail "$2: no line matches /$1/"; fi
}

as admin ./src/install.sh
expect_exit 2 "no flag exits 2"

as admin ./src/install.sh --admin --no-admin
expect_exit 2 "--admin with --no-admin exits 2"

as admin bash src/steps/0050-k8s.sh
expect_exit 2 "a step run without TOOLS_MODE exits 2"

as admin "printf 'Admin Name\nadmin@example.com\n' | ./src/install.sh --admin $STEPS"
expect_exit 0 "admin --admin $STEPS exits 0"

as work "printf 'Work Name\nwork@example.com\n' | ./src/install.sh --no-admin $STEPS"
expect_exit 0 "work --no-admin $STEPS exits 0"

if [ -s "$SUDO_LOG" ]; then
  cp "$SUDO_LOG" "$OUT"
  fail "work --no-admin called sudo"
else
  pass "work --no-admin never called sudo"
fi

as work ./src/install.sh --no-admin k8s
expect_exit 1 "work --no-admin k8s exits 1"
expect_output "^k8s: run src/install.sh --admin k8s first$" "work --no-admin k8s asks for --admin k8s first"

as work ./src/install.sh --no-admin nope
expect_exit 1 "an unknown step exits 1"

as admin ./src/install.sh --admin --list
expect_output "^0320-yq +done$" "admin --list shows yq done"
as work ./src/install.sh --no-admin --list
expect_output "^0320-yq +done$" "work --list shows yq done"

for account in admin work; do
  as "$account" "echo '# edit' >>src/steps/0125-go.sh && echo '# edit' >>src/steps/0320-yq.sh"
done

as admin ./src/install.sh --admin --list
expect_output "^0125-go +changed$" "admin --list shows an edited step as changed"
as work ./src/install.sh --no-admin --list
expect_output "^0125-go +waiting$" "work --list shows an edited step with a machine-wide part as waiting"
expect_output "^0320-yq +changed$" "work --list shows an edited home-only step as changed"

as work ./src/install.sh --no-admin yq
expect_exit 0 "work --no-admin runs an edited home-only step before --admin does"

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "failed assertions: $FAILURES"
  exit 1
fi
echo "every assertion passed"
