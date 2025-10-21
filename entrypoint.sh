#!/usr/bin/env bash
set -euo pipefail

ZIPDIR="/zip"
EXEDIR="/exe"

echo "[INFO] Starting Bitmain IP Reporter Docker..."
mkdir -p "$ZIPDIR" "$EXEDIR"
chmod -R 777 "$ZIPDIR" "$EXEDIR"

# Check for zip or exe
ZIP_FILE=$(find "$ZIPDIR" -maxdepth 1 -type f -iname "*.zip" | head -n 1 || true)
EXE_FILE=$(find "$EXEDIR" -maxdepth 1 -type f -iname "*.exe" | head -n 1 || true)

if [[ -n "$ZIP_FILE" ]]; then
    echo "[INFO] Found ZIP file: $ZIP_FILE"
    echo "[INFO] Extracting to $EXEDIR..."
    rm -rf "${EXEDIR:?}/"*
    unzip -o "$ZIP_FILE" -d "$EXEDIR"
fi

# Recheck for exe after extraction
if [[ -z "$EXE_FILE" ]]; then
    EXE_FILE=$(find "$EXEDIR" -type f -iname "*.exe" | head -n 1 || true)
fi

if [[ -z "$EXE_FILE" ]]; then
    echo "[ERROR] No EXE file found in $EXEDIR or $ZIPDIR!"
    echo "[INFO] Container idling. Add your .zip or .exe and it will stay running."
    exec tail -f /dev/null
fi

echo "[INFO] Found executable: $EXE_FILE"

# Start GUI backend
echo "[INFO] Starting GUI backend..."
/init &

# Give GUI time to come up
sleep 8

echo "[INFO] Launching application with Wine..."
cd "$EXEDIR"
/usr/bin/wine64 "$EXE_FILE" &

# Stream everything to stdout
echo "[INFO] Container running. Streaming logs..."
exec tail -F /tmp/xvfb.log /tmp/nginx-access.log /tmp/nginx-error.log 2>/dev/null
