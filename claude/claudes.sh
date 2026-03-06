#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
docker run -it --rm \
  -v "$(pwd)":/workspace \
  -v claude-code-home:/home/claude \
  -v "$HOME/.claude/scripts":/host/.claude/scripts:ro \
  -v "$HOME/.claude/skills":/host/.claude/skills:ro \
  -v "$HOME/.claude/plugins":/host/.claude/plugins:ro \
  -v "$HOME/.claude/agents":/host/.claude/agents:ro \
  -w /workspace \
  claude-code --dangerously-skip-permissions
