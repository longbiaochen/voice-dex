#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="VoiceDex"
APP_DIR="$ROOT/dist/$APP_NAME.app"
LAUNCH_AGENT_LABEL="com.longbiao.voicedex"
LAUNCH_AGENT_PLIST="$HOME/Library/LaunchAgents/$LAUNCH_AGENT_LABEL.plist"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

"$ROOT/scripts/package_app.sh" >/dev/null

if launchctl list | grep -q "$LAUNCH_AGENT_LABEL"; then
  launchctl kickstart -k "gui/$(id -u)/$LAUNCH_AGENT_LABEL" >/dev/null 2>&1 &
else
  open -n "$APP_DIR"
fi
