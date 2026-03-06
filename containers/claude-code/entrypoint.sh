#!/bin/bash
# Ensure claude owns home (named volume may be root-owned)
chown -R claude:claude /home/claude 2>/dev/null || true

# Copy baked-in settings
mkdir -p /home/claude/.claude
cp -f /opt/claude-config/settings.json /home/claude/.claude/settings.json 2>/dev/null || true

# Copy host user config dirs (scripts, skills, plugins, agents)
for dir in scripts skills plugins agents; do
  if [ -d "/host/.claude/$dir" ]; then
    mkdir -p "/home/claude/.claude/$dir"
    cp -rf "/host/.claude/$dir/." "/home/claude/.claude/$dir/"
  fi
done

chmod -R +x /home/claude/.claude/scripts/*.sh 2>/dev/null || true
chown -R claude:claude /home/claude/.claude 2>/dev/null || true

exec gosu claude claude "$@"
