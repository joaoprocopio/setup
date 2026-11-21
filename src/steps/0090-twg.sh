#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Atlassian Teamwork Graph CLI. The flags skip the browser login and the agent skills, so the install needs no input.
curl -fsSL --retry 2 https://teamwork-graph.atlassian.com/cli/install | bash -s -- --yes --skip-login --skip-skills

note "run \`twg login\`, then \`twg doctor\`"
