#!/usr/bin/env bash
set -euo pipefail

APPDIR="/opt/app"
ZIPDIR="/zip"
LOGFILE="/config/wine.log"

export WINEARCH="${WINEARCH:-win64}"
export WINEPREFIX="${WINEPREFIX:-/config/wineprefix}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree,mshtml=}"
export WINEDEBUG="${WINEDEBUG:--all}"
export XDG_RUNTIME_DIR=/tmp

echo "[INFO] Bitmain IP Reporter GUI container started..."
echo "[INFO] Checking for ZIP file in ${ZIPDIR}..."

# Optional download
if [[ -n "${ZIP_URL:-}" && "${ZIP_URL:-}" != "" ]]; then
    echo "[INFO] Downloading from ${ZIP_URL}"
    wget -O "${ZIP_FILE}" "${ZIP_URL}" || {
        echo "[ERROR] Failed to fetch ZIP from ${ZIP_URL}"
        exec sleep infinity
    }
fi

ZIP_FILE=$(find "${ZIPDIR}" -maxdepth 1 -type f -iname "*.zip" | head -n 1 || true)
if [[ -z "${ZIP_FILE}" ]]; then
    echo "[ERROR] No ZIP found in ${ZIPDIR}. Please mount one to /zip"
    exec sleep infinity
fi

echo "[INFO] Extracting ${ZIP_FILE} ..."
rm -rf "${APPDIR:?}/"*
unzip -o "${ZIP_FILE}" -d "${APPDIR}"

EXE_FILE=$(find "${APPDIR}" -type f -iname "*.exe" | head -n 1 || true)
if [[ -z "${EXE_FILE}" ]]; then
    echo "[ERROR] No .exe found after extraction!"
    exec sleep infinity
fi

echo "[INFO] Launching ${EXE_FILE} via Wine..."
wine "${EXE_FILE}" >"${LOGFILE}" 2>&1 &
sleep 3
echo "[INFO] Wine started successfully. Logs at ${LOGFILE}"
