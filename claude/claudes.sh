#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

log() { echo "[claudes] $*"; }

# Extract credentials from macOS Keychain (same approach as mycli)
extract_credentials() {
  local creds
  creds=$(security find-generic-password -s "Claude Code-credentials" -w 2>/dev/null) && {
    echo "$creds"
    return 0
  }
  creds=$(security find-internet-password -s "claude.ai" -w 2>/dev/null) && {
    echo "$creds"
    return 0
  }
  echo "Error: could not read credentials from keychain. Is Claude Code authenticated?" >&2
  return 1
}

# Prompt for session name
SESSION_NAME=$(gum input --placeholder "Session name")

# Create temp dir for prepared files, cleaned up on exit
STAGING_DIR=$(mktemp -d "$HOME/.claude/.claudes-staging.XXXXXX")
trap 'rm -rf "$STAGING_DIR"' EXIT

# 1. Extract and write credentials
log "Extracting credentials from macOS Keychain..."
CREDS=$(extract_credentials)
log "Credentials extracted (${#CREDS} bytes)"
echo -n "$CREDS" > "$STAGING_DIR/credentials.json"

# 2. Prepare settings.json: resolve symlink, inject skipDangerousModePermissionPrompt
log "Preparing settings.json..."
HOST_SETTINGS="$HOME/.claude/settings.json"
if [ -f "$HOST_SETTINGS" ]; then
  jq '. + {"skipDangerousModePermissionPrompt": true}' "$HOST_SETTINGS" > "$STAGING_DIR/settings.json"
else
  echo '{"skipDangerousModePermissionPrompt": true}' > "$STAGING_DIR/settings.json"
fi

# 3. Prepare .claude.json: inject hasCompletedOnboarding
log "Preparing .claude.json..."
if [ -f "$HOME/.claude.json" ]; then
  jq '. + {"hasCompletedOnboarding": true}' "$HOME/.claude.json" > "$STAGING_DIR/claude.json"
else
  echo '{"hasCompletedOnboarding": true}' > "$STAGING_DIR/claude.json"
fi

# 4. Build volume mounts
# Staging files go to /home/claude/.host-config/ to avoid Docker Desktop nested mount bug
# (mixing file and directory mounts under the same parent creates dirs instead of files)
HOST_PLUGINS_DIR="$HOME/.claude/plugins"
VOLUMES=(
  -v "$(pwd)":/workspace
  -v "$STAGING_DIR":/home/claude/.host-config:ro
  -v claude-plugins:/home/claude/.claude/plugins
)

# Mount host config dirs that exist (scripts, skills, agents)
for dir in scripts skills agents; do
  host_dir="$HOME/.claude/$dir"
  if [ -d "$host_dir" ]; then
    VOLUMES+=(-v "$host_dir":/home/claude/.claude/"$dir":ro)
    log "Mounting ~/.claude/$dir"
  fi
done

# Mount plugin metadata files for entrypoint to install via claude CLI
if [ -d "$HOST_PLUGINS_DIR" ]; then
  for meta in known_marketplaces.json installed_plugins.json; do
    if [ -f "$HOST_PLUGINS_DIR/$meta" ]; then
      VOLUMES+=(-v "$HOST_PLUGINS_DIR/$meta":/home/claude/.host-plugins/"$meta":ro)
    fi
  done
  log "Mounting plugin metadata for sync"
fi

log "Starting container with workspace $(pwd)..."
docker run -it --rm \
  "${VOLUMES[@]}" \
  -w /workspace \
  claude-code --dangerously-skip-permissions --remote-control --name "$SESSION_NAME"
