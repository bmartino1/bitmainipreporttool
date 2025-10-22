#!/bin/sh
set -eu

# Persistent HOME for app
export HOME="${HOME:-/config}"
export WINEPREFIX="$HOME/wine64"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp/runtime-app}"

ZIPDIR="/zip"
EXEDIR="/exe"

# Root-needed prep (use sudo because this runs as 'app')
sudo mkdir -p "/config" "$WINEPREFIX" "$ZIPDIR" "$EXEDIR" "$XDG_RUNTIME_DIR"
sudo chown -R app:app "/config" "$ZIPDIR" "$EXEDIR" "$XDG_RUNTIME_DIR"
sudo chmod 700 "$XDG_RUNTIME_DIR"

# If a ZIP is present, unpack into /exe (root file perms on host dirs won’t block us)
ZIP_FILE="$(find "$ZIPDIR" -maxdepth 1 -type f -iname '*.zip' | head -n 1 || true)"
if [ -n "$ZIP_FILE" ]; then
  echo "[INFO] Extracting payload: $ZIP_FILE"
  sudo rm -rf "${EXEDIR:?}/"*
  sudo unzip -o "$ZIP_FILE" -d "$EXEDIR" >/dev/null
  sudo chown -R app:app "$EXEDIR"
fi

# Find an .exe
EXE_FILE="$(find "$EXEDIR" -type f -iname '*.exe' | head -n 1 || true)"
if [ -z "$EXE_FILE" ]; then
  echo "[ERROR] No .exe found in $EXEDIR. Idling."
  exec sleep infinity
fi
echo "[INFO] Executable: $EXE_FILE"

# First-run Wine prefix init (as app — NOT sudo!)
if [ ! -f "$WINEPREFIX/system.reg" ] || [ ! -d "$WINEPREFIX/drive_c" ]; then
  echo "[INFO] Initializing Wine prefix at $WINEPREFIX"
  wineboot --init || true
  wineserver -w || true
fi

# Launch app (as app). The baseimage already provides X/VNC; no xvfb-run needed.
cd "$EXEDIR"
exec /usr/bin/wine64 "$EXE_FILE"
