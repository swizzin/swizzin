# Calibre-Web Automated (CWA)

Calibre-Web Automated (CWA) is an enhanced fork of Calibre-Web that adds automatic ingest, conversion, metadata enforcement and many automations to provide an all-in-one web frontend for your Calibre library.

This repository provides an optional package installation: `calibrewebautomated`.

## Quick Install

You can install using the Box tool:

```
box install calibrewebautomated
```

Or run the installer script directly:

```
bash /usr/local/bin/swizzin/install/calibrewebautomated.sh
```

The installer will:

- Create a dedicated system user `calibrewebautomated`
- Install CWA under `/opt/calibrewebautomated` and create a venv in `/opt/.venv/calibrewebautomated`
- Create a systemd service `calibrewebautomated` that runs the application
- Optionally create an nginx proxy `applications/calibrewebautomated` if nginx is present

## Post-install

- Default web port: 8083 (change if you plan to run `calibreweb` concurrently)
- Default admin login: `admin` / `admin123` (please change immediately)
- CWA supports many environment variables (e.g., `CWA_PORT_OVERRIDE`, `NETWORK_SHARE_MODE`, `TRUSTED_PROXY_COUNT`) — consult upstream docs for details: https://github.com/crocodilestick/Calibre-Web-Automated

## Migration from stock Calibre-Web

CWA is designed to be drop-in compatible with many Calibre-Web installations. To migrate:

1. Stop your running `calibreweb` instance
2. Install `calibrewebautomated` and bind the same `/config` folder (or copy config folder) and the same library folder to ensure users & settings are preserved

## Testing the container locally

A helper test script is provided to quickly verify a CWA container can start and serve HTTP requests:

```
./tests/docker/test_cwa_container.sh [image]
```

- By default the script pulls `crocodilestick/calibre-web-automated:latest` and runs it with temporary directories for config/library/ingest.
- Optional flags:
  - `--keep` — keep the container running after the test (useful for debugging)
  - `--debug` — enable shell trace
- The script will report the mapped host port and perform a basic HTTP check.
- If you receive a Docker permission error, run with `sudo` or add your user to the `docker` group:

```
sudo ./tests/docker/test_cwa_container.sh --keep --debug
# or
sudo usermod -aG docker $(whoami) && newgrp docker
```

## Uninstall

```
box remove calibrewebautomated
```

Or:

```
bash /usr/local/bin/swizzin/remove/calibrewebautomated.sh
```

---

For more advanced configuration and backwards compatibility tips, please refer to the upstream project: https://github.com/crocodilestick/Calibre-Web-Automated
