#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

# uv lands in ~/.local/bin, which the terminal step already puts on PATH.
curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
