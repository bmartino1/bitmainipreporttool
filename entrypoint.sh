#!/usr/bin/env bash
set -euo pipefail

APPDIR="/opt/app"
ZIPDIR="/zip"

echo "[INFO] Starting Bitmain IP Reporter container..."
echo "[INFO] Looking for ZIP file in ${ZIPDIR}"

ZIP_FILE=$(find "${ZIPDIR}" -maxdepth 1 -type f -iname "*.zip" | head -n 1 || true)

if [[ -z "${ZIP_FILE}" ]]; then
    echo "[ERROR] No ZIP file found in ${ZIPDIR}"
    echo "Please mount a volume with your IP Reporter ZIP to /zip"
    sleep infinity
fi

echo "[INFO] Extracting ${ZIP_FILE} ..."
rm -rf "${APPDIR:?}/"*
unzip -o "${ZIP_FILE}" -d "${APPDIR}"

EXE_FILE=$(find "${APPDIR}" -type f -iname "*.exe" | head -n 1 || true)

if [[ -z "${EXE_FILE}" ]]; then
    echo "[ERROR] No .exe found inside the ZIP!"
    sleep infinity
fi

echo "[INFO] Found EXE: ${EXE_FILE}"
echo "[INFO] Launching application with Wine..."

exec wine "${EXE_FILE}"
