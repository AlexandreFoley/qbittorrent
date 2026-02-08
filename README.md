# qBittorrent container Image

Custom qBittorrent Docker image based on [hotio/qbittorrent](https://github.com/hotio/qbittorrent) with environment-based configuration.

## Features

- Multi-arch support (amd64, arm64)
- Automatic configuration via environment variables of webui user, password and download directory.
- Weekly automated builds when upstream updates

## Usage

> **⚠️ Security Warning**: Strongly consider using Docker/Podman secrets for `WEBUI_PASSWORD` to avoid exposing credentials in container configurations.

### Using Secrets

With podman, you can create a secret like so:
```bash
echo 'your-admin-password' | podman secret create qbittorrent_password -
```

### Compose

```yaml
services:
  qbittorrent:
    image: ghcr.io/alexandrefoley/qbittorrent:latest
    container_name: qbittorrent
    environment:
      - WEBUI_USERNAME=admin
      - DOWNLOAD_FOLDER=/Media/torrents
    secrets:
      - qbittorrent_password
    ports:
      - "8080:8080"
    volumes:
      - ./config:/config
      - ./Media:/Media
    restart: unless-stopped

secrets:
  qbittorrent_password:
  # Declare the secret as external, indicating it's managed outside the compose file
    external: true
    type: env
    target: WEBUI_PASSWORD 
```

## Environment Variables

| Variable | Description | Default | Security Note |
|----------|-------------|---------|---------------|
| `WEBUI_USERNAME` | WebUI username | `admin` | |
| `WEBUI_PASSWORD` | WebUI password | _(none - required)_ | **Use Docker/Podman secrets** |
| `DOWNLOAD_FOLDER` | Default download path | `/Media/torrents` | |

## Building

```bash
podman build -t qbittorrent .
```

## License

See [LICENSE](LICENSE)

