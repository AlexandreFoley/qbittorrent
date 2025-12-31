# qBittorrent Docker Image

Custom qBittorrent Docker image based on [hotio/qbittorrent](https://github.com/hotio/qbittorrent) with environment-based configuration.

## Features

- Multi-arch support (amd64, arm64)
- Automatic configuration via environment variables
- Published to GitHub Container Registry (GHCR)
- Weekly automated builds when upstream updates

## Usage

> **⚠️ Security Warning**: Strongly consider using Docker/Podman secrets for `WEBUI_PASSWORD` to avoid exposing credentials in container configurations and logs.

### Docker Compose (with Secrets - Recommended)

```yaml
services:
  qbittorrent:
    image: ghcr.io/alexandrefoley/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - WEBUI_USERNAME=admin
      - DOWNLOAD_FOLDER=/Media/torrents
      WEBUI_PASSWORD: /run/secrets/webui_password
    secrets:
      - webui_password
    ports:
      - "8080:8080"
    volumes:
      - ./config:/config
      - ./Media:/Media
    restart: unless-stopped

secrets:
  webui_password:
  # Declare the secret as external, indicating it's managed outside the compose file
    external: true
```

### Docker Compose (Basic)

```yaml
services:
  qbittorrent:
    image: ghcr.io/alexandrefoley/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - WEBUI_USERNAME=admin
      - WEBUI_PASSWORD=your_secure_password
      - DOWNLOAD_FOLDER=/Media/torrents
    ports:
      - "8080:8080"
    volumes:
      - ./config:/config
      - ./Media:/Media
    restart: unless-stopped
```

### Docker Run

```bash
docker run -d \
  --name qbittorrent \
  -e WEBUI_USERNAME=admin \
  -e WEBUI_PASSWORD=your_secure_password \
  -e DOWNLOAD_FOLDER=/Media/torrents \
  -p 8080:8080 \
  -v ./config:/config \
  -v ./Media:/Media \
  ghcr.io/alexandrefoley/qbittorrent:latest
```

## Environment Variables

| Variable | Description | Default | Security Note |
|----------|-------------|---------|---------------|
| `WEBUI_USERNAME` | WebUI username | `admin` | |
| `WEBUI_PASSWORD` | WebUI password | `kR9#mP2vL8qX5nB@wT3jZ` | **Use Docker/Podman secrets instead** |
| `DOWNLOAD_FOLDER` | Default download path | `/Media/torrents` | |

### Using Secrets (Recommended)

Create a secrets file:
```bash
mkdir -p secrets
echo "your_secure_password" > secrets/webui_password.txt
chmod 600 secrets/webui_password.txt
```

The container will automatically read from `/run/secrets/webui_password` if the `WEBUI_PASSWORD` environment variable is not set.

## Building

```bash
docker build -t qbittorrent .
```

## License

See [LICENSE](LICENSE)
