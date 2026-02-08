FROM ghcr.io/hotio/qbittorrent:latest

# Default environment variables for qBittorrent configuration
ENV WEBUI_USERNAME=admin \
    DOWNLOAD_FOLDER=/media/torrents

# Copy s6 service configurations
COPY root/ /

# Make service scripts executable
RUN chmod +x /etc/s6-overlay/s6-rc.d/post-qbittorrent/configure-qbittorrent.sh
