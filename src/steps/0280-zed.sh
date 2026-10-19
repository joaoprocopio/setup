#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://zed.dev/docs/linux
# The installer never deletes its download, so TMPDIR puts it in $WORK,
# which lib.sh removes on exit.
curl -fsSL https://zed.dev/install.sh | TMPDIR="$WORK" sh
