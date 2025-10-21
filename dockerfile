FROM jlesage/baseimage-gui:debian-12-v4.7.1

# Metadata
LABEL maintainer="bitmain" \
      description="Run Bitmain IP Reporter via Wine in a web-based GUI container."

# Environment
ENV APP_NAME="ip-reporter" \
    WINEARCH=win64 \
    WINEPREFIX=/config/wineprefix \
    ZIP_URL="" \
    ZIP_FILE="/zip/ip-reporter.zip"

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wine winetricks unzip cabextract wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /config /opt/app

# Copy entrypoint script
COPY entrypoint.sh /startapp.sh
RUN chmod +x /startapp.sh

# Default ports (web VNC + optional)
EXPOSE 5800 5900

# Entry point
ENTRYPOINT ["/startapp.sh"]
