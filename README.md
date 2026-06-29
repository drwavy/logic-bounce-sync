# logic-bounce-sync

Automatically sync Logic Pro bounces to iCloud Drive whenever you make a bounce. No manual uploads required.

Native macOS tools, no third-party apps.

## How It Works

A `launchd` file watcher monitors your `~/Music/Logic` folder for any filesystem changes. When Logic writes a new bounce, the watcher fires a shell script that rsyncs all `Bounces` subfolders to a mirrored folder in iCloud Drive. iCloud handles the rest.

```
~/Music/Logic/
  My Track.logicx/
    Bounces/  

← watched, syncs to →

~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/Bounces Sync/
  My Track.logicx/
    Bounces/
```

- 30-second delay after detection gives Logic time to finish writing before rsync runs
- `--ignore-existing` on rsync means the script is safe to run repeatedly — only new files are copied, nothing is overwritten
- macOS notification for each successful sync
- New projects are picked up automatically without needing config changes

## Project Structure

```
logic-bounce-sync/
  sync_bounces.sh   sync script
  install.sh        install script and watcher
  uninstall.sh      uninstall script and watcher
  LICENSE
  README.md
```

### `sync_bounces.sh`

The main script. Walks every project folder inside `~/Music/Logic`, finds subfolders named `Bounces`, and rsyncs their contents to a mirrored path in iCloud Drive.

The find loop:

```bash
while IFS= read -r -d '' bounces_dir; do
  project_name=$(basename "$(dirname "$bounces_dir")")
  dest_project="$DEST_DIR/$project_name/Bounces"
  mkdir -p "$dest_project"
  rsync -a --ignore-existing "$bounces_dir/" "$dest_project/"
done < <(find "$SOURCE_DIR" -mindepth 2 -maxdepth 2 -type d -name "Bounces" -print0)
```

- `find -mindepth 2 -maxdepth 2` targets folders named `Bounces` that sit exactly one level inside a project folder so it won't accidentally match a `Bounces` folder nested deeper in a project's internal structure
- `-print0` and `IFS= read -r -d ''` handle filenames with spaces safely, (specifically matters for Logic project names)
- `basename "$(dirname "$bounces_dir")"` gets the project folder name so the destination mirrors the source structure
- `rsync -a` preserves file attributes and handles the copy; `--ignore-existing` skips files already at the destination, making the script safe to run at any time without risk of overwriting

### `install.sh`

Runs once to set everything up.

1. Copies `sync_bounces.sh` to `~/Scripts/` and makes it executable
2. Checks that iCloud Drive is present at its expected path
3. Generates the `launchd` plist dynamically using `$(whoami)` and `$HOME`, so paths are correct for any user without manual editing
4. Writes the plist to `~/Library/LaunchAgents/` and loads it with `launchctl`

The plist is generated rather than bundled as a static file so there's no step where you have to find and replace a hardcoded username.

### `install.sh` - the launchd plist it generates

```xml
<key>WatchPaths</key>
<array>
    <string>/Users/yourname/Music/Logic</string>
</array>

<key>ThrottleInterval</key>
<integer>30</integer>
```

- `WatchPaths` tells launchd to watch the Logic folder recursively. Any filesystem event like file created, modified, renamed, will wake the agent
- `ThrottleInterval` sets a 30-second minimum between firings. This is the buffer that lets Logic finish writing the bounce before rsync runs. Without it, rsync could read an incomplete file
- The plist is stored at `~/Library/LaunchAgents/`, which is the correct location for per-user agents that run without elevated privileges and persist across reboots

### `uninstall.sh`

Unloads the launchd agent, removes the plist from `LaunchAgents`, and removes the sync script from `~/Scripts/`. Does not touch anything in `~/Music/Logic` or iCloud Drive.

## Requirements

- macOS (tested on Ventura and later)
- Logic Pro project save path set to `~/Music/Logic` (default)
- iCloud Drive

## Install

```bash
git clone https://github.com/drwavy/logic-bounce-sync.git
cd logic-bounce-sync
chmod +x install.sh
./install.sh
```

1. Copies the sync script to `~/Scripts/sync_bounces.sh`
2. Generates a `launchd` plist with your correct username and paths
3. Loads the watcher - it's active immediately and persists across reboots

## Uninstall

```bash
./uninstall.sh
```

Stops the watcher and removes the script and plist. Does not touch your Logic projects or any files in iCloud Drive.

## Useful Commands

```bash
# Check the watcher is running
launchctl list | grep bouncessync

# Watch sync activity live
tail -f ~/Library/Logs/bounces_sync.log

# Run a manual sync
~/Scripts/sync_bounces.sh

# Stop auto-sync
launchctl unload ~/Library/LaunchAgents/com.$(whoami).bouncessync.plist

# Start it again
launchctl load ~/Library/LaunchAgents/com.$(whoami).bouncessync.plist
```

## Customization

The sync script uses `$HOME` throughout, so paths resolve correctly for any user. If your Logic projects live somewhere other than `~/Music/Logic`, edit the `SOURCE_DIR` variable at the top of `sync_bounces.sh` before running the installer.

If you want to sync to a different destination than iCloud Downloads, update `DEST_DIR` in the same file.

## License

MIT — see [LICENSE](LICENSE).