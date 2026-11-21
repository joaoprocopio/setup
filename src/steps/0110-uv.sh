#!/usr/bin/env bash
source "$(dirname "$0")/../lib.sh"

curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
