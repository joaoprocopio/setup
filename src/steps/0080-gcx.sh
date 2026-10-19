#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# Grafana CLI, https://grafana.com/docs/grafana/latest/as-code/observability-as-code/grafana-cli/gcx/installation/
# Installs the latest release into ~/.local/bin after checking its SHA-256.
curl -fsSL https://raw.githubusercontent.com/grafana/gcx/main/scripts/install.sh | sh

note "rode \`gcx login <contexto> --server https://<stack>.grafana.net\` e depois \`gcx config check\`"
