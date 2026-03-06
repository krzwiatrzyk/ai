#!/bin/bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // .tool_input | tostring')
mkdir -p "$PWD/.claude"
echo "[$(date -Iseconds)] [$TOOL] $CMD" >> "$PWD/.claude/command_history.log"
