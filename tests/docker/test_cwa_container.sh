#!/usr/bin/env bash
# Integration test: start a Calibre-Web Automated container and verify basic functionality
# Usage: ./tests/docker/test_cwa_container.sh [image]

set -euo pipefail
IFS=$'\n\t'

# Basic args:
# - pass an image as first argument, or use default
# - flags: --keep to preserve container after test, --debug to enable shell tracing, --open to launch the URL in a browser
KEEP=false
DEBUG=false
OPEN=false
IMAGE="crocodilestick/calibre-web-automated:latest"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --keep)
            KEEP=true; shift;;
        --debug)
            DEBUG=true; shift;;
        --open)
            OPEN=true; shift;;
        --image)
            IMAGE="$2"; shift 2;;
        *)
            IMAGE="$1"; shift;;
    esac
done

NAME="swizzin_cwa_test_$$"
CONFIG_DIR=$(mktemp -d)
LIB_DIR=$(mktemp -d)
INGEST_DIR=$(mktemp -d)
LOG_FILE="/tmp/${NAME}.log"

# Ensure temp dirs are writable by the app user (UID 1000 in this image).
echo "Preparing temporary dirs: $CONFIG_DIR $LIB_DIR $INGEST_DIR" | tee -a "$LOG_FILE"
if chown -R 1000:1000 "$CONFIG_DIR" "$LIB_DIR" "$INGEST_DIR" 2>/dev/null; then
    echo "Chowned temp dirs to 1000:1000" | tee -a "$LOG_FILE"
else
    echo "Warning: unable to chown temp dirs (run with sudo to allow chown), continuing anyway." | tee -a "$LOG_FILE"
fi

TIMEOUT=90

if [ "$DEBUG" = "true" ]; then
    set -x
fi

cleanup() {
    rc=$?
    echo "\nCleaning up..." | tee -a "$LOG_FILE"
    # Dump logs for debugging
    echo "----- Container logs (last 500 lines) -----" | tee -a "$LOG_FILE"
    docker logs "$NAME" --tail 500 2>&1 | sed 's/^/LOG: /' | tee -a "$LOG_FILE" || true
    # Only remove the container if not asked to keep it
    if [ "$KEEP" != "true" ]; then
        docker rm -f "$NAME" &>/dev/null || true
    else
        echo "Keeping container $NAME as requested (--keep)" | tee -a "$LOG_FILE"
        echo "Temporary host dirs retained for inspection:" | tee -a "$LOG_FILE"
        echo "  CONFIG_DIR: $CONFIG_DIR" | tee -a "$LOG_FILE"
        echo "  LIB_DIR:    $LIB_DIR" | tee -a "$LOG_FILE"
        echo "  INGEST_DIR: $INGEST_DIR" | tee -a "$LOG_FILE"
    fi
    # Remove temporary host dirs only when not keeping the container
    if [ "$KEEP" != "true" ]; then
        rm -rf "$CONFIG_DIR" "$LIB_DIR" "$INGEST_DIR" || true
    else
        echo "Not removing temp dirs because --keep was requested" | tee -a "$LOG_FILE"
    fi
    exit ${rc}
}
trap cleanup EXIT

echo "Test start: image=$IMAGE" | tee "$LOG_FILE"

if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required to run this test" | tee -a "$LOG_FILE"
    exit 2
fi
# Verify we can talk to the Docker daemon (permission check)
if ! docker info >/dev/null 2>&1; then
    err=$(docker info 2>&1 || true)
    echo "Cannot connect to Docker daemon: ${err%%$'\n'*}" | tee -a "$LOG_FILE"
    echo "Hint: you may need to run the script with sudo, or add your user to the 'docker' group: 'sudo usermod -aG docker \$(whoami) && newgrp docker'" | tee -a "$LOG_FILE"
    echo "Example: sudo $0 --keep --debug" | tee -a "$LOG_FILE"
    exit 2
fi

echo "Pulling image $IMAGE..." | tee -a "$LOG_FILE"
docker pull "$IMAGE" >> "$LOG_FILE" 2>&1

# Run container
run_opts="-d"
if [ "$KEEP" != "true" ]; then
    run_opts="$run_opts --rm"
fi

echo "Running: docker run $run_opts --name \"$NAME\" -e PUID=1000 -e PGID=1000 -e TZ=UTC -e NETWORK_SHARE_MODE=false -v \"$CONFIG_DIR\":/config -v \"$LIB_DIR\":/calibre-library -v \"$INGEST_DIR\":/cwa-book-ingest -P \"$IMAGE\"" | tee -a "$LOG_FILE"
container_id=$(docker run $run_opts \
    --name "$NAME" \
    -e PUID=1000 -e PGID=1000 -e TZ=UTC \
    -e NETWORK_SHARE_MODE=false \
    -v "$CONFIG_DIR":/config \
    -v "$LIB_DIR":/calibre-library \
    -v "$INGEST_DIR":/cwa-book-ingest \
    -P "$IMAGE")

echo "Container started: $container_id" | tee -a "$LOG_FILE"

# discover mapped host port for exposed 8083
host_port=""
start_ts=$(date +%s)
while [ -z "$host_port" ]; do
    if docker ps -q -f name="^/${NAME}$" >/dev/null; then
        map=$(docker port "$NAME" 8083/tcp || true)
        if [ -n "$map" ]; then
            # format is 0.0.0.0:12345 or :::12345 (take the first mapping line)
            host_port=$(echo "$map" | head -n1 | sed -E 's/.*:([0-9]+)$/\1/')
            break
        fi
    fi
    now=$(date +%s)
    if [ $((now - start_ts)) -ge $TIMEOUT ]; then
        echo "Timed out waiting for port mapping (after ${TIMEOUT}s)" | tee -a "$LOG_FILE"
        docker logs "$NAME" --tail 200 | tee -a "$LOG_FILE"
        exit 3
    fi
    sleep 1
done

echo "Detected CWA host port: $host_port" | tee -a "$LOG_FILE"

# First verify service is responding inside the container
echo "Checking CWA inside container (http://127.0.0.1:8083/) ..." | tee -a "$LOG_FILE"
internal_start=$(date +%s)
# Give the app a bit more time to initialize on slower hosts
internal_timeout=60
internal_code="000"
while true; do
    internal_code=$(docker exec "$NAME" curl -s -k -o /dev/null -w '%{http_code}' http://127.0.0.1:8083/ 2>/dev/null || echo "000")
    echo "Internal http_code=$internal_code" | tee -a "$LOG_FILE"
    # Accept any 2xx or 3xx as a successful response (200 redirect to /login is common)
    if [[ "$internal_code" =~ ^(2|3) ]]; then
        echo "Internal container check: OK (http_code=$internal_code)" | tee -a "$LOG_FILE"
        break
    fi
    if [ $(( $(date +%s) - internal_start )) -ge $internal_timeout ]; then
        echo "Internal healthcheck timed out after ${internal_timeout}s, last code=$internal_code" | tee -a "$LOG_FILE"
        echo "Container process list and logs:" | tee -a "$LOG_FILE"
        docker exec -w / "$NAME" ps aux | sed 's/^/PROC: /' | tee -a "$LOG_FILE" || true
        docker logs "$NAME" --tail 200 | tee -a "$LOG_FILE"
        break
    fi
    sleep 1
done

# Wait for HTTP to return 2xx/3xx on host port
echo "Waiting for HTTP on http://127.0.0.1:$host_port/ ..." | tee -a "$LOG_FILE"
start_ts=$(date +%s)
while true; do
    http_code=$(curl -s -k -o /dev/null -w '%{http_code}' "http://127.0.0.1:$host_port/" || echo "000")
    # Accept 2xx or 3xx (redirect to /login is normal on fresh installs)
    if [[ "$http_code" =~ ^(2|3) ]]; then
        echo "CWA responded with HTTP $http_code" | tee -a "$LOG_FILE"
        break
    fi
    now=$(date +%s)
    if [ $((now - start_ts)) -ge $TIMEOUT ]; then
        echo "Timed out waiting for HTTP (after ${TIMEOUT}s), last http_code=$http_code" | tee -a "$LOG_FILE"
        echo "Internal check last value: $internal_code" | tee -a "$LOG_FILE"
        echo "Container logs (last 200 lines):" | tee -a "$LOG_FILE"
        docker logs "$NAME" --tail 200 | tee -a "$LOG_FILE"
        echo "Temp dir ownerships:" | tee -a "$LOG_FILE"
        ls -ld "$CONFIG_DIR" "$LIB_DIR" "$INGEST_DIR" 2>/dev/null | sed 's/^/OWN: /' | tee -a "$LOG_FILE" || true
        echo "Docker inspect mounts:" | tee -a "$LOG_FILE"
        docker inspect "$NAME" --format '{{json .Mounts}}' 2>/dev/null | sed 's/^/MNT: /' | tee -a "$LOG_FILE" || true
        exit 4
    fi
    sleep 2
done

# Basic optional checks: /opds should return at least 200 or 401; check root contains 'Calibre' or CWA title
echo "Checking root page content" | tee -a "$LOG_FILE"
content=$(curl -s -k "http://127.0.0.1:$host_port/")
if echo "$content" | grep -qi "calibre" || echo "$content" | grep -qi "cwa"; then
    echo "Root page content looks correct" | tee -a "$LOG_FILE"
else
    echo "Root page content did not contain expected keywords, saving snippet" | tee -a "$LOG_FILE"
    echo "$content" | sed -n '1,200p' >> "$LOG_FILE"
fi

# helper: try to open a URL using available desktop helpers
open_url() {
    url="$1"
    echo "Attempting to open URL: $url" | tee -a "$LOG_FILE"
    if command -v xdg-open >/dev/null 2>&1; then
        xdg-open "$url" >/dev/null 2>&1 &
        echo "Launched with xdg-open" | tee -a "$LOG_FILE"
        return 0
    fi
    if command -v gio >/dev/null 2>&1; then
        gio open "$url" >/dev/null 2>&1 &
        echo "Launched with gio open" | tee -a "$LOG_FILE"
        return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
        python3 -m webbrowser "$url" >/dev/null 2>&1 &
        echo "Launched with python3 -m webbrowser" | tee -a "$LOG_FILE"
        return 0
    fi
    echo "No desktop opener found (xdg-open/gio/python3). Please open in your browser: $url" | tee -a "$LOG_FILE"
    return 1
}

# Success
cat <<EOF | tee -a "$LOG_FILE"

SUCCESS: Calibre-Web Automated container responded successfully.
Container: $NAME ($container_id)
Host port: $host_port
Config dir: $CONFIG_DIR
Library dir: $LIB_DIR
Ingest dir: $INGEST_DIR
Logs: $LOG_FILE

Open in your browser: http://127.0.0.1:$host_port/  (it will likely redirect to /login)

The container will be removed automatically. If you want to keep it, run this script with your own docker run command (or use --keep in a future version).
EOF

# If requested, try to open the URL in the user's desktop/browser environment
if [ "$OPEN" = "true" ]; then
    open_url "http://127.0.0.1:$host_port/" || true
fi

exit 0
