#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

needs fnm

# https://code.claude.com/docs/en/setup
if ! command -v claude >/dev/null; then
  curl -fsSL https://claude.ai/install.sh | bash
fi

# fnm puts node on PATH only in ~/.zshrc, which bash does not read.
eval "$(fnm env --shell bash)"
needs fnm npm

# agent-browser uses the Chrome from the chrome step.
npm install --global agent-browser

# `skills add` exits 0 on a skill it cannot find, so this checks that each one landed.
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

# Leaves out Matt's grilling, because mine in $ASSETS takes the name.
skills_add mattpocock/skills \
  ask-matt code-review codebase-design chief-of-staff diagnosing-bugs \
  domain-modeling grill-me grill-with-docs handoff implement implement-spec \
  improve-codebase-architecture pr prototype research retro \
  setup-matt-pocock-skills tdd teach to-questionnaire to-spec to-tickets \
  triage wait-what wayfinder writing-for-agents

# Leaves out Emil's prototype, because mattpocock/skills takes the name.
skills_add emilkowalski/skill apple-design

# Leaves out Vercel's writing-guidelines, because mine in $ASSETS takes the name.
skills_add vercel-labs/agent-skills \
  vercel-composition-patterns \
  vercel-react-best-practices vercel-react-view-transitions

skills_add vercel-labs/agent-browser agent-browser

# $ASSETS mirrors ~/.claude, except claude.json, which installs to ~/.claude.json.
mkdir -p ~/.claude
rsync -a --omit-dir-times --exclude=/settings.json --exclude=/claude.json \
  --itemize-changes "$ASSETS/" ~/.claude/

# Deep-merges instead of copying, because Claude Code keeps its login and project state in these files.
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
alias sonnet='claude --model sonnet'
EOF
