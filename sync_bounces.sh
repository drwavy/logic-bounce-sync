#!/bin/bash
# sync_bounces.sh
# Copies new bounces from all Logic Pro projects to an iCloud Drive folder.
# Safe to run repeatedly. only copies files that don't already exist at the destination.

SOURCE_DIR="$HOME/Music/Logic"
DEST_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Downloads/Bounces Sync"

# Sanity checks
if [ ! -d "$SOURCE_DIR" ]; then
  osascript -e 'display alert "Bounces Sync — Error" message "Logic folder not found at ~/Music/Logic."'
  exit 1
fi

if [ ! -d "$DEST_DIR" ]; then
  mkdir -p "$DEST_DIR" || {
    osascript -e 'display alert "Bounces Sync — Error" message "Could not create destination folder. Is iCloud Drive enabled?"'
    exit 1
  }
fi

# Sync every Bounces subfolder
COPIED=0

while IFS= read -r -d '' bounces_dir; do
  project_name=$(basename "$(dirname "$bounces_dir")")
  dest_project="$DEST_DIR/$project_name/Bounces"
  mkdir -p "$dest_project"
  rsync -a --ignore-existing "$bounces_dir/" "$dest_project/"
  COPIED=$((COPIED + 1))
done < <(find "$SOURCE_DIR" -mindepth 2 -maxdepth 2 -type d -name "Bounces" -print0)

# Notification
osascript -e "display notification \"Synced $COPIED project bounce folder(s) to iCloud.\" with title \"Bounces Sync ✓\""
