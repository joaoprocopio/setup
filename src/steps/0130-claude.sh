#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# https://code.claude.com/docs/en/setup
if ! command -v claude >/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# fnm puts node on PATH only in ~/.zshrc, which bash does not read.
eval "$(fnm env --shell bash)"

# agent-browser finds the Chrome from the chrome step, so skip its install.
npm install --global agent-browser

# `skills add` exits 0 on a skill it cannot find, so check each one landed.
skills_add() {
  local repo=$1 skill
  shift
  for skill in "$@"; do rm -rf ~/.claude/skills/"$skill"; done
  DO_NOT_TRACK=1 npx --yes skills@latest add "$repo" \
    --global --agent claude-code --copy --yes --skill "$@"
  for skill in "$@"; do
    if [ ! -f ~/.claude/skills/"$skill"/SKILL.md ]; then
      echo "$repo has no skill named $skill" >&2
      exit 1
    fi
  done
}

# Leaves out Matt's grilling, because mine in $ASSETS takes it.
skills_add mattpocock/skills \
  ask-matt code-review codebase-design diagnosing-bugs \
  domain-modeling grill-me grill-with-docs handoff implement implement-spec \
  improve-codebase-architecture pr prototype research retro \
  setup-matt-pocock-skills tdd teach to-questionnaire to-spec to-tickets \
  triage wait-what wayfinder writing-for-agents

# Leaves out Emil's prototype, because mattpocock/skills takes that name.
skills_add emilkowalski/skill apple-design

# Leaves out Vercel's writing-guidelines, because mine in $ASSETS takes it.
skills_add vercel-labs/agent-skills \
  vercel-composition-patterns \
  vercel-react-best-practices vercel-react-view-transitions

skills_add vercel-labs/agent-browser agent-browser

# $ASSETS mirrors ~/.claude path for path, so a file's place there is its
# install path. claude.json is the one exception: it installs to
# ~/.claude.json, outside ~/.claude.
mkdir -p ~/.claude
rsync -a --omit-dir-times --exclude=/settings.json --exclude=/claude.json \
  --itemize-changes "$ASSETS/" ~/.claude/

# A JSON config is deep-merged instead of copied, so keys set elsewhere
# survive and keys set here win. Claude Code also writes its login and
# project state to ~/.claude.json, which a copy would wipe out.
json_merge() {
  local asset=$1 target=$2 live=()
  if [ -f "$target" ]; then live=("$target"); fi
  jq -s 'reduce .[] as $s ({}; . * $s)' "${live[@]}" "$asset" >"$WORK/merged.json"
  rsync --checksum --itemize-changes "$WORK/merged.json" "$target"
}
json_merge "$ASSETS/settings.json" ~/.claude/settings.json
json_merge "$ASSETS/claude.json" ~/.claude.json

rc_block ~/.zshrc <<'EOF'
alias claude='command claude --system-prompt-file "$HOME/.claude/SYSTEM.md"'
alias haiku='claude --model haiku'
EOF
