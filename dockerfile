# Bitmain IP Reporter minimal Wine GUI image
FROM jlesage/baseimage-gui:debian-12-v4.9.0


# ---- Locale ----
#English Locales
RUN \
    add-pkg locales && \
    sed-patch 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8

# GUI Base Image Default env
ARG APP_ICON="https://cdn-icons-png.freepik.com/256/12429/12429352.png"
RUN set-cont-env APP_NAME "Wine GUI"
RUN set-cont-env DISPLAY_WIDTH "1280"
RUN set-cont-env DISPLAY_HEIGHT "800"
RUN set-cont-env APP_VERSION "Latest"

# Install other Depends libraries for base iamge and script
RUN apt-get -yq update && apt-get -yq install \
    libfontconfig1 \
    libxcb1 \
    libxrender1 \
    libxcb-icccm4 \
    libxkbcommon-x11-0 \
    libxext6 \
    libxfixes3 \
    libxi6 \
    build-essential \
    autoconf \
    libssl-dev \
    libboost-dev \
    libboost-chrono-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    qtbase5-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libqrencode-dev \
    libdb5.3++-dev \
    libdb5.3-dev xdg-utils apt-utils curl jq tar gnupg ca-certificates git xz-utils bash mc nano vim sudo


# ---- Base setup: parnioa double check install minimal networking + tools ----
RUN set -eux; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get -y upgrade; \
    apt-get install -y --no-install-recommends \
        bash wget curl iputils-ping dnsutils unzip ca-certificates gnupg2 \
        software-properties-common apt-utils; 

# ---- Prepare folders BEFORE Wine installation ----
RUN mkdir -p /zip /exe && chmod -R 777 /zip /exe

# ---- Add WineHQ repository and install full Wine (official method) ----
RUN set -eux; \
    dpkg --add-architecture i386; \
    mkdir -pm755 /etc/apt/keyrings; \
    wget -qO /etc/apt/keyrings/winehq-archive.key https://dl.winehq.org/wine-builds/winehq.key; \
    wget -qO /etc/apt/sources.list.d/winehq-bookworm.sources https://dl.winehq.org/wine-builds/debian/dists/bookworm/winehq-bookworm.sources; \
    apt-get update; \
    # Stage 1: deps
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libfaudio0 libfaudio0:i386 \
        libasound2 libasound2:i386 \
        libgphoto2-6 libgphoto2-6:i386 \
        libgsm1 libgsm1:i386 \
        libjpeg62-turbo libjpeg62-turbo:i386 \
        libmpg123-0 libmpg123-0:i386 \
        libopenal1 libopenal1:i386 \
        libosmesa6 libosmesa6:i386 \
        libsdl2-2.0-0 libsdl2-2.0-0:i386 \
        libv4l-0 libv4l-0:i386 \
        libxcomposite1 libxcomposite1:i386 \
        libxinerama1 libxinerama1:i386 \
        libxrandr2 libxrandr2:i386 \
        libxxf86vm1 libxxf86vm1:i386 \
        libwine libwine:i386 fonts-wine; \
    # Stage 2: main Wine package
    DEBIAN_FRONTEND=noninteractive apt-get install -y --install-recommends winehq-stable; 

# === Install Wine + dependencies ===============================
RUN set -eux; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --install-recommends \
        winehq-stable unzip cabextract xdg-utils locales \
        libfontconfig1 libxcb1 libxrender1 libxcb-icccm4 libxkbcommon-x11-0 \
        libxext6 libxfixes3 libxi6 xvfb x11vnc openbox supervisor procps tini

# === Install Winetricks manually ===============================
RUN set -eux; \
    wget -O /tmp/winetricks.deb http://ftp.de.debian.org/debian/pool/contrib/w/winetricks/winetricks_20230212-2_all.deb; \
    apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends binutils /tmp/winetricks.deb; \
    rm -f /tmp/winetricks.deb

# ============================== ADDED: Wine First Run Configure ==============================
# Create a Wine prefix non-interactively during build so the first container start is clean.
# No volume is declared for the prefix here; this only primes the image.

# Prefer 64-bit prefix; can be overridden at build time: --build-arg WINEARCH=win32
ARG WINEARCH=win64
ENV WINEARCH=${WINEARCH}

# Prefix + runtime env; suppress Mono/Gecko prompts; quiet noisy debug
ENV WINEPREFIX=/wineprefix \
    XDG_RUNTIME_DIR=/tmp/xdg \
    WINEDLLOVERRIDES=mscoree,mshtml= \
    WINEDEBUG=-all

# Prepare dirs with permissive perms to avoid UID/GID issues later
RUN set -eux; \
    mkdir -p "${WINEPREFIX}" "${XDG_RUNTIME_DIR}"; \
    chmod -R 777 "${WINEPREFIX}" "${XDG_RUNTIME_DIR}"

# Headless first-run init (with Xvfb). Left here to preserve prior steps; harmless if X dies.
RUN set -eux; \
    export WINEPREFIX="${WINEPREFIX}"; \
    export WINEARCH="${WINEARCH}"; \
    xvfb-run -a -s "-screen 0 1024x768x24" wineboot --init || true; \
    wineserver -w || true; \
    winetricks -q -f corefonts settings fontsmooth=rgb || true; \
    wineserver -w || true; \
    if [ ! -f "${WINEPREFIX}/system.reg" ] || [ ! -f "${WINEPREFIX}/user.reg" ] || [ ! -d "${WINEPREFIX}/drive_c" ]; then \
        xvfb-run -a -s "-screen 0 1024x768x24" wineboot --init || true; \
        wineserver -w || true; \
    fi

# ---- EXTRA: Pure headless first-run (NO X server at all) ----
# Unset DISPLAY so Wine never tries to talk to X; still creates a valid prefix.
ENV WINEDLLOVERRIDES=${WINEDLLOVERRIDES};winemenubuilder.exe=d
RUN set -eux; \
    export WINEPREFIX="${WINEPREFIX}"; \
    export WINEARCH="${WINEARCH}"; \
    (unset DISPLAY || true); \
    wineboot --init || true; \
    wineserver -w || true; \
    winetricks -q -f corefonts settings fontsmooth=rgb || true; \
    wineserver -w || true; \
    test -f "${WINEPREFIX}/system.reg" && test -f "${WINEPREFIX}/user.reg" && test -d "${WINEPREFIX}/drive_c"
# =============================================================================================

# ---- Clean only once ----
#RUN apt-get clean && rm -rf /var/lib/apt/lists/*

# ---- Expose GUI + make folders persistent ----
VOLUME ["/zip", "/exe"]
EXPOSE 5800 5900

# ---- Add entrypoint ----
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
