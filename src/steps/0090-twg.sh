#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Atlassian Teamwork Graph CLI, https://developer.atlassian.com/cloud/twg-cli/getting-started/installation/, with flags that skip the browser login and the agent skills.
curl -fsSL --retry 2 https://teamwork-graph.atlassian.com/cli/install | bash -s -- --yes --skip-login --skip-skills

note "run \`twg login\`, then \`twg doctor\`"
