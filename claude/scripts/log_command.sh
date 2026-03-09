#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
[[ "$TOOL" != "Bash" ]] && exit 0
CMD=$(echo "$INPUT" | jq -r '.tool_input.command')
mkdir -p "$PWD/.claude"
echo "[$(date -Iseconds)] $CMD" >> "$PWD/.claude/command_history.log"
