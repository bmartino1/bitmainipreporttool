#!/usr/bin/env bash
set -euo pipefail

APPDIR="/opt/app"
ZIPDIR="/zip"

echo "[INFO] Starting Bitmain IP Reporter container..."
echo "[INFO] Checking for ZIP file in ${ZIPDIR}..."

# Support user-supplied download URL or pre-mounted file
if [[ -n "${ZIP_URL}" && "${ZIP_URL}" != "" ]]; then
    echo "[INFO] Downloading from ${ZIP_URL}"
    wget -O "${ZIP_FILE}" "${ZIP_URL}" || {
        echo "[ERROR] Failed to fetch ZIP from ${ZIP_URL}"
        sleep infinity
    }
fi

# Detect ZIP file (user may replace it anytime)
ZIP_FILE=$(find "${ZIPDIR}" -maxdepth 1 -type f -iname "*.zip" | head -n 1 || true)

if [[ -z "${ZIP_FILE}" ]]; then
    echo "[ERROR] No ZIP found in ${ZIPDIR}. Please mount one to /zip"
    sleep infinity
fi

echo "[INFO] Extracting ${ZIP_FILE} ..."
rm -rf "${APPDIR:?}/"*
unzip -o "${ZIP_FILE}" -d "${APPDIR}"

EXE_FILE=$(find "${APPDIR}" -type f -iname "*.exe" | head -n 1 || true)
if [[ -z "${EXE_FILE}" ]]; then
    echo "[ERROR] No .exe found after extraction!"
    sleep infinity
fi

echo "[INFO] Launching ${EXE_FILE} via Wine..."
exec wine "${EXE_FILE}"
