#!/usr/bin/env bash
# PR provider for the status line on GitHub. The contract is in
# bitbucket.org.sh. `gh pr list --head` rather than `gh pr view`, because
# view also returns a merged or closed PR for the branch.

set -euo pipefail

gh pr list --head "$1" --state open --limit 20 --json number,baseRefName,isDraft,url,isCrossRepository \
  -q 'map(select(.isCrossRepository | not)) | .[0] // empty | [.number, .baseRefName, .isDraft, .url] | @tsv' 2>/dev/null
