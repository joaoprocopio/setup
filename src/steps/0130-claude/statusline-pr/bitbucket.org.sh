#!/usr/bin/env bash
# PR provider for the status line, picked by the file name matching the
# remote host. To add a forge, copy this file as <host>.sh.
#
# Contract: runs inside the repo with the branch name as $1. Prints one line,
# id<TAB>destination branch<TAB>draft (true|false)<TAB>url, for the branch's
# open PR, or nothing when there is none. Exits non-zero when the lookup
# fails, so the status line keeps its last answer.

set -euo pipefail

twg -o json --output-summary none bb prs query --source "$1" --limit 20 2>/dev/null |
  jq -r 'map(select(.source.repository.full_name == .destination.repository.full_name)) | .[0] // empty | [.id, .destination.branch.name, (.draft // false), .links.html.href] | @tsv'
