#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Atlassian Teamwork Graph CLI, https://developer.atlassian.com/cloud/twg-cli/getting-started/installation/
# By default the installer opens the browser for OAuth and installs agent
# skills. These flags skip both, so the install runs without you.
curl -fsSL --retry 2 https://teamwork-graph.atlassian.com/cli/install | bash -s -- --yes --skip-login --skip-skills

note "rode \`twg login\` e depois \`twg doctor\`"
