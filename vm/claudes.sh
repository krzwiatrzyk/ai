#!/bin/bash
set -eu -o pipefail

SESSION_NAME=$(gum input --placeholder "Session name")

limactl shell klaudiusz -- claude --dangerously-skip-permissions --remote-control --name "$SESSION_NAME"
# --append-system-prompt "$(cat prompt.md)"
