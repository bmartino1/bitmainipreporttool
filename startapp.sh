#!/usr/bin/env bash
set -euo pipefail

APPDIR="/opt/app"
ZIPDIR="/zip"
LOGFILE="/config/wine.log"
INIT_HOOK_DIR="/etc/cont-init.d"
INIT_SCRIPT="${INIT_HOOK_DIR}/55-start-wine.sh"

# --- Ensure sane defaults for jlesage init ---
export USER_ID="${USER_ID:-99}"
export GROUP_ID="${GROUP_ID:-100}"
export XDG_RUNTIME_DIR="/tmp/xdg-runtime-dir"
mkdir -p "${XDG_RUNTIME_DIR}"
chmod 700 "${XDG_RUNTIME_DIR}"

export WINEARCH="${WINEARCH:-win64}"
export WINEPREFIX="${WINEPREFIX:-/config/wineprefix}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree,mshtml=}"
export WINEDEBUG="${WINEDEBUG:--all}"

echo "[INFO] ============================================================="
echo "[INFO] Bitmain IP Reporter GUI container starting..."
echo "[INFO] ============================================================="
echo "[INFO] Checking for ZIP file in ${ZIPDIR}..."

# ---------------------------------------------------------
# Optional ZIP download
# ---------------------------------------------------------
if [[ -n "${ZIP_URL:-}" && "${ZIP_URL:-}" != "" ]]; then
    echo "[INFO] Downloading ZIP from ${ZIP_URL}"
    wget -O "${ZIP_FILE}" "${ZIP_URL}" || {
        echo "[ERROR] Failed to fetch ZIP from ${ZIP_URL}"
        exec sleep infinity
    }
fi

# ---------------------------------------------------------
# Locate or validate ZIP file
# ---------------------------------------------------------
ZIP_FILE=$(find "${ZIPDIR}" -maxdepth 1 -type f -iname "*.zip" | head -n 1 || true)
if [[ -z "${ZIP_FILE}" ]]; then
    echo "[ERROR] No ZIP found in ${ZIPDIR}. Please mount one to /zip"
    exec sleep infinity
fi

echo "[INFO] Extracting ${ZIP_FILE} ..."
rm -rf "${APPDIR:?}/"*
unzip -o "${ZIP_FILE}" -d "${APPDIR}"

# ---------------------------------------------------------
# Locate EXE file
# ---------------------------------------------------------
EXE_FILE=$(find "${APPDIR}" -type f -iname "*.exe" | head -n 1 || true)
if [[ -z "${EXE_FILE}" ]]; then
    echo "[ERROR] No .exe found after extraction!"
    exec sleep infinity
fi

echo "[INFO] Found executable: ${EXE_FILE}"
echo "[INFO] Preparing Wine init integration..."

# ---------------------------------------------------------
# Generate /etc/cont-init.d/55-start-wine.sh dynamically
# ---------------------------------------------------------
mkdir -p "${INIT_HOOK_DIR}"

cat > "${INIT_SCRIPT}" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

APPDIR="/opt/app"
LOGFILE="/config/wine.log"
EXE_FILE=$(find "${APPDIR}" -type f -iname "*.exe" | head -n 1 || true)

export WINEARCH="${WINEARCH:-win64}"
export WINEPREFIX="${WINEPREFIX:-/config/wineprefix}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-mscoree,mshtml=}"
export WINEDEBUG="${WINEDEBUG:--all}"
export XDG_RUNTIME_DIR="/tmp/xdg-runtime-dir"

if [[ -z "${EXE_FILE}" ]]; then
    echo "[ERROR] [cont-init.d] No EXE found at container init time!"
    exit 1
fi

echo "[INFO] [cont-init.d] Launching Wine app: ${EXE_FILE}"
wine "${EXE_FILE}" >"${LOGFILE}" 2>&1 &
sleep 2
echo "[INFO] [cont-init.d] Wine background process started."
EOF

chmod +x "${INIT_SCRIPT}"

echo "[INFO] Wine init script registered at ${INIT_SCRIPT}"
echo "[INFO] Logs will be written to ${LOGFILE}"

# ---------------------------------------------------------
# Final handoff to baseimage init system
# ---------------------------------------------------------
echo "[INFO] ============================================================="
echo "[INFO] Handing control to /init (VNC, Openbox, supervisor, etc.)"
echo "[INFO] ============================================================="
exec /init
