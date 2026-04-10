#!/bin/bash
# Copy staged config files to their expected locations
# (mounted to .host-config/ to avoid Docker Desktop nested mount bug)
HOST_CONFIG="/home/claude/.host-config"

[ -f "$HOST_CONFIG/credentials.json" ] && cp "$HOST_CONFIG/credentials.json" /home/claude/.claude/.credentials.json
[ -f "$HOST_CONFIG/settings.json" ]    && cp "$HOST_CONFIG/settings.json" /home/claude/.claude/settings.json
[ -f "$HOST_CONFIG/claude.json" ]      && cp "$HOST_CONFIG/claude.json" /home/claude/.claude.json

# Sync plugins from host metadata via claude CLI (cached in named volume)
PLUGIN_META="/home/claude/.host-plugins"

# Fix ownership of named volume (Docker creates it as root:root)
sudo chown claude:claude /home/claude/.claude/plugins

# Cache current state from CLI once
INSTALLED_MARKETPLACES=$(claude plugin marketplace list 2>/dev/null || true)
INSTALLED_PLUGINS=$(claude plugin list 2>/dev/null || true)

if [ -f "$PLUGIN_META/known_marketplaces.json" ]; then
  for repo in $(jq -r '.[] | .source.repo // empty' "$PLUGIN_META/known_marketplaces.json"); do
    if echo "$INSTALLED_MARKETPLACES" | grep -qF "$repo"; then
      echo "[entrypoint] Marketplace already added: $repo"
      continue
    fi
    echo "[entrypoint] Adding marketplace: $repo"
    claude plugin marketplace add "$repo" 2>/dev/null || continue
  done
fi

if [ -f "$PLUGIN_META/installed_plugins.json" ]; then
  jq -r '.plugins | to_entries[] | "\(.value[0].scope // "user") \(.key)"' "$PLUGIN_META/installed_plugins.json" | \
  while read -r scope plugin_id; do
    [ "$scope" = "project" ] && scope="user"
    if echo "$INSTALLED_PLUGINS" | grep -qF "$plugin_id"; then
      echo "[entrypoint] Plugin already installed: $plugin_id"
      continue
    fi
    echo "[entrypoint] Installing plugin: $plugin_id (scope: $scope)"
    claude plugin install --scope "$scope" "$plugin_id" 2>/dev/null || continue
  done
fi

exec claude "$@"
