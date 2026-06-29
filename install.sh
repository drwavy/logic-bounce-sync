#!/bin/bash
# install.sh
# Sets up logic-bounce-sync on your Mac.
# Installs the sync script and a launchd watcher that fires automatically on every bounce.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/Scripts"
PLIST_LABEL="com.$(whoami).bouncessync"
PLIST_PATH="$HOME/Library/LaunchAgents/$PLIST_LABEL.plist"
LOG_DIR="$HOME/Library/Logs"

echo ""
echo "  logic-bounce-sync installer"
echo "  ────────────────────────────"
echo ""

# 1. Install sync script 
echo "→ Installing sync script to $INSTALL_DIR/sync_bounces.sh"
mkdir -p "$INSTALL_DIR"
cp "$SCRIPT_DIR/sync_bounces.sh" "$INSTALL_DIR/sync_bounces.sh"
chmod +x "$INSTALL_DIR/sync_bounces.sh"

# 2. Check iCloud Drive is available
ICLOUD_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs"
if [ ! -d "$ICLOUD_DIR" ]; then
  echo ""
  echo "  iCloud Drive not found at ~/Library/Mobile Documents/com~apple~CloudDocs"
  echo "  Make sure iCloud Drive is enabled in System Settings → Apple ID → iCloud."
  echo ""
  exit 1
fi

# 3. Generate plist with correct paths
echo "→ Writing launchd plist to $PLIST_PATH"

mkdir -p "$HOME/Library/LaunchAgents"

cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${INSTALL_DIR}/sync_bounces.sh</string>
    </array>

    <key>WatchPaths</key>
    <array>
        <string>${HOME}/Music/Logic</string>
    </array>

    <!-- Wait 30s after a change before firing, giving Logic time to finish writing. -->
    <key>ThrottleInterval</key>
    <integer>30</integer>

    <key>RunAtLoad</key>
    <false/>

    <key>StandardOutPath</key>
    <string>${LOG_DIR}/bounces_sync.log</string>

    <key>StandardErrorPath</key>
    <string>${LOG_DIR}/bounces_sync_error.log</string>
</dict>
</plist>
EOF

# 4. Unload any existing instance, then load fresh
echo "→ Loading launchd agent"
launchctl unload "$PLIST_PATH" 2>/dev/null || true
launchctl load "$PLIST_PATH"

# 5. Verify
if launchctl list | grep -q "$PLIST_LABEL"; then
  echo ""
  echo "  ✓ Done. logic-bounce-sync is active."
  echo ""
  echo "  Every bounce in ~/Music/Logic will automatically sync to:"
  echo "  ~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/Bounces Sync"
  echo ""
  echo "  Logs:  tail -f ~/Library/Logs/bounces_sync.log"
  echo "  Stop:  launchctl unload $PLIST_PATH"
  echo "  Start: launchctl load $PLIST_PATH"
  echo ""
else
  echo ""
  echo "  ✗ Something went wrong — agent didn't load."
  echo "  Try running: launchctl load $PLIST_PATH"
  echo ""
  exit 1
fi
