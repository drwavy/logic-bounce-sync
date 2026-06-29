#!/bin/bash
# uninstall.sh
# Removes logic-bounce-sync cleanly. Does not touch your Logic projects or iCloud files.

PLIST_LABEL="com.$(whoami).bouncessync"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
SCRIPT_PATH="$HOME/Scripts/sync_bounces.sh"

echo ""
echo "  logic-bounce-sync uninstaller"
echo "  ──────────────────────────────"
echo ""

# Stop and remove launchd agent
if [ -f "$PLIST_PATH" ]; then
  echo "→ Unloading launchd agent"
  launchctl unload "$PLIST_PATH" 2>/dev/null || true
  rm "$PLIST_PATH"
  echo "→ Removed $PLIST_PATH"
else
  echo "  No launchd plist found — skipping"
fi

# Remove sync script
if [ -f "$SCRIPT_PATH" ]; then
  rm "$SCRIPT_PATH"
  echo "→ Removed $SCRIPT_PATH"
else
  echo "  No sync script found at $SCRIPT_PATH — skipping"
fi

echo ""
echo "  ✓ Done. Auto-sync is disabled."
echo "  Your bounces in iCloud Drive have not been touched."
echo ""
