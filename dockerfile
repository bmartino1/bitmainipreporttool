# Bitmain IP Reporter (Wine + Web VNC)
FROM jlesage/baseimage-gui:debian-12-v4.9.0

ENV APP_NAME="Bitmain IP Reporter" \
    DISPLAY_WIDTH=1280 \
    DISPLAY_HEIGHT=800 \
    WINEARCH=win64 \
    WINEPREFIX=/config/wineprefix \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    WINEDEBUG=-all \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    ZIP_FILE="/zip/ip-reporter.zip"

# prereqs and repo components
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        wget curl ca-certificates gnupg2 software-properties-common xz-utils; \
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
        sed -i 's/components: *main$/components: main contrib non-free non-free-firmware/' /etc/apt/sources.list.d/debian.sources; \
    elif [ -f /etc/apt/sources.list ]; then \
        sed -i 's/main$/main contrib non-free non-free-firmware/' /etc/apt/sources.list; \
    else \
        echo "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list; \
        echo "deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list; \
        echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list; \
    fi; \
    apt-get update

# multi-arch then winehq repo
RUN set -eux; \
    dpkg --add-architecture i386; \
    mkdir -pm755 /etc/apt/keyrings; \
    wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key; \
    wget -qO /etc/apt/sources.list.d/winehq-bookworm.sources https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources; \
    apt-get update

# wine + libs (NOT winetricks via apt)
RUN set -eux; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --install-recommends \
        winehq-stable unzip cabextract xdg-utils locales \
        libfontconfig1 libxcb1 libxrender1 libxcb-icccm4 libxkbcommon-x11-0 \
        libxext6 libxfixes3 libxi6; \
    apt-get clean; rm -rf /var/lib/apt/lists/*

# winetricks from Debian contrib .deb (bookworm)
RUN set -eux; \
    wget -O /tmp/winetricks.deb http://ftp.de.debian.org/debian/pool/contrib/w/winetricks/winetricks_20230212-2_all.deb; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends /tmp/winetricks.deb; \
    rm -f /tmp/winetricks.deb; \
    apt-get clean; rm -rf /var/lib/apt/lists/*

# locale
RUN set -eux; sed -i 's/# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen; locale-gen

# wine prefix init (non-interactive)
RUN set -eux; mkdir -p /config /opt/app /zip; wineboot --init || true

# jlesage UI env
RUN set-cont-env APP_NAME "${APP_NAME}" && \
    set-cont-env DISPLAY_WIDTH "${DISPLAY_WIDTH}" && \
    set-cont-env DISPLAY_HEIGHT "${DISPLAY_HEIGHT}"

VOLUME ["/config", "/zip"]
EXPOSE 5800 5900

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
