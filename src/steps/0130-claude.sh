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

skills_add mattpocock/skills \
  code-review codebase-design diagnosing-bugs domain-modeling grill-me \
  grill-with-docs grilling handoff implement implement-spec \
  improve-codebase-architecture pr prototype research retro \
  setup-matt-pocock-skills tdd teach to-questionnaire to-spec to-tickets \
  triage wayfinder writing-for-agents

# Leaves out Emil's prototype, because mattpocock/skills takes that name.
skills_add emilkowalski/skill apple-design

# Leaves out Vercel's writing-guidelines, because mine in $ASSETS takes it.
skills_add vercel-labs/agent-skills \
  vercel-composition-patterns \
  vercel-react-best-practices vercel-react-view-transitions

skills_add vercel-labs/agent-browser agent-browser

# $ASSETS mirrors ~/.claude path for path, so a file's place there is its
# install path.
mkdir -p ~/.claude
rsync -a --omit-dir-times --exclude=/settings.json \
  --itemize-changes "$ASSETS/" ~/.claude/

# settings.json is deep-merged instead of copied, so keys set elsewhere
# survive and keys set here win.
live=()
if [ -f ~/.claude/settings.json ]; then live=(~/.claude/settings.json); fi
jq -s 'reduce .[] as $s ({}; . * $s)' "${live[@]}" "$ASSETS/settings.json" >"$WORK/settings.json"
rsync --checksum --itemize-changes "$WORK/settings.json" ~/.claude/settings.json

rc_block ~/.zshrc <<'EOF'
alias claude='command claude --system-prompt-file "$HOME/.claude/SYSTEM.md"'
# btw joins its words into one prompt, so a question needs no quotes. noglob
# stops zsh from reading the ? at the end of a question as a glob.
_btw() { claude --model haiku --effort low -p "$*"; }
alias btw='noglob _btw'
EOF
