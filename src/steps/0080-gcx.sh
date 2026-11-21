#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Grafana CLI, https://grafana.com/docs/grafana/latest/as-code/observability-as-code/grafana-cli/gcx/installation/
curl -fsSL https://raw.githubusercontent.com/grafana/gcx/main/scripts/install.sh | sh

note "run \`gcx login <context> --server https://<stack>.grafana.net\`, then \`gcx config check\`"
