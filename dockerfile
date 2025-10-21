# Bitmain IP Reporter (Wine + Web VNC)
FROM jlesage/baseimage-gui:debian-12-v4.9.0

LABEL maintainer="bitmain" \
      version="1.1" \
      description="Run Bitmain IP Reporter via Wine in a web-based GUI container."

# === Environment and Locales ===
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

# === Enable contrib & WineHQ repo ===
RUN set -eux; \
    sed -i 's/^deb \(.*\) main$/deb \1 main contrib non-free non-free-firmware/' /etc/apt/sources.list; \
    dpkg --add-architecture i386; \
    apt-get update; \
    apt-get install -y --no-install-recommends gnupg2 software-properties-common; \
    mkdir -pm755 /etc/apt/keyrings; \
    wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key; \
    wget -qO /etc/apt/sources.list.d/winehq-bookworm.sources https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources; \
    apt-get update

# === Install all packages ===
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        winehq-stable wine64 wine32 winetricks unzip cabextract wget curl jq tar gnupg \
        ca-certificates git xz-utils build-essential autoconf apt-utils sudo vim nano bash mc \
        libfontconfig1 libxcb1 libxrender1 libxcb-icccm4 libxkbcommon-x11-0 \
        libxext6 libxfixes3 libxi6 libssl-dev libboost-dev \
        libboost-chrono-dev libboost-filesystem-dev libboost-program-options-dev \
        libboost-system-dev libboost-test-dev libboost-thread-dev qtbase5-dev \
        libprotobuf-dev protobuf-compiler libqrencode-dev libdb5.3++-dev libdb5.3-dev \
        xdg-utils locales unattended-upgrades && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# === Locale setup ===
RUN sed-patch 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen

# === Pre-initialize Wine prefix to prevent first-launch delay ===
RUN mkdir -p /config /opt/app /zip && \
    wineboot --init || true

VOLUME ["/config", "/zip"]

# === Copy entrypoint ===
COPY entrypoint.sh /startapp.sh
RUN chmod +x /startapp.sh

# === GUI meta ===
RUN set-cont-env APP_NAME "Bitmain IP Reporter" && \
    set-cont-env APP_ICON "${APP_ICON}" && \
    set-cont-env APP_VERSION "${APP_VERSION}" && \
    set-cont-env DISPLAY_WIDTH "${DISPLAY_WIDTH}" && \
    set-cont-env DISPLAY_HEIGHT "${DISPLAY_HEIGHT}"

EXPOSE 5800 5900
ENTRYPOINT ["/startapp.sh"]
