# Bitmain IP Reporter (Wine + Web VNC) Docker
# ======================================================
FROM jlesage/baseimage-gui:debian-12-v4.9.0

LABEL maintainer="bitmain" \
      version="1.0" \
      description="Run Bitmain IP Reporter via Wine in a web-based GUI container."

# ======================================================
# === Environment and Locales ==========================
# ======================================================
ENV APP_NAME="ip-reporter" \
    APP_VERSION="Latest" \
    WINEARCH=win64 \
    WINEPREFIX=/config/wineprefix \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    ZIP_URL="" \
    ZIP_FILE="/zip/ip-reporter.zip" \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=800 \
    APP_ICON="https://bitcoin.org/img/icons/opengraph.png"

# English Locales
RUN add-pkg locales && \
    sed-patch 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen

# ======================================================
# === System + GUI + Wine Dependencies =================
# ======================================================
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends \
        wine winetricks unzip cabextract wget curl jq tar gnupg ca-certificates git xz-utils \
        build-essential autoconf apt-utils sudo vim nano bash mc \
        libfontconfig1 libxcb1 libxrender1 libxcb-icccm4 libxkbcommon-x11-0 \
        libxext6 libxfixes3 libxi6 libssl-dev libboost-dev \
        libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
        libboost-system-dev libboost-test-dev libboost-thread-dev qtbase5-dev \
        libprotobuf-dev protobuf-compiler libqrencode-dev libdb5.3++-dev libdb5.3-dev \
        xdg-utils unattended-upgrades && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ======================================================
# === Setup directories ================================
# ======================================================
RUN mkdir -p /config /opt/app /zip
VOLUME ["/config", "/zip"]

# ======================================================
# === Copy and set entrypoint ==========================
# ======================================================
COPY entrypoint.sh /startapp.sh
RUN chmod +x /startapp.sh

# ======================================================
# === GUI base image metadata ==========================
# ======================================================
RUN set-cont-env APP_NAME "Bitmain IP Reporter" && \
    set-cont-env APP_ICON "${APP_ICON}" && \
    set-cont-env APP_VERSION "${APP_VERSION}" && \
    set-cont-env DISPLAY_WIDTH "${DISPLAY_WIDTH}" && \
    set-cont-env DISPLAY_HEIGHT "${DISPLAY_HEIGHT}"

# ======================================================
# === Expose ports for Web VNC =========================
# ======================================================
EXPOSE 5800 5900

# ======================================================
# === Entrypoint =======================================
# ======================================================
ENTRYPOINT ["/startapp.sh"]
