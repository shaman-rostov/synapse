#!/usr/bin/env bash
# Generates a throwaway SQLite homeserver, starts it, checks /health, the libpq psycopg2 loads and the rebuilt gosu.
set -euo pipefail
IMAGE=${1:?image}
dir=$(mktemp -d); data=$dir/data; mkdir "$data"
name=synapse-test-$$
# the generated files (and the mount point) belong to the image's synapse user, so the container empties it
trap 'docker rm -f "$name" >/dev/null 2>&1 || true; docker run --rm -v "$data:/data" --entrypoint sh "$IMAGE" -c "rm -rf /data/*" >/dev/null 2>&1 || true; rm -rf "$dir"' EXIT
env=(-e SYNAPSE_SERVER_NAME=test.local -e SYNAPSE_REPORT_STATS=no)
docker run --rm "${env[@]}" -v "$data:/data" "$IMAGE" generate >/dev/null
docker run -d --name "$name" "${env[@]}" -v "$data:/data" -p 127.0.0.1::8008 "$IMAGE" >/dev/null
port=$(docker port "$name" 8008/tcp | head -1 | sed 's/.*://')
for _ in $(seq 60); do curl -fsS "http://127.0.0.1:$port/health" 2>/dev/null | grep -q OK && break; sleep 1; done
curl -fsS "http://127.0.0.1:$port/health" | grep -q OK || { echo "FAIL: /health"; docker logs "$name"; exit 1; }
libpq=$(docker exec "$name" python -c 'import psycopg2.extensions as e; print(e.libpq_version())')
docker exec "$name" gosu --version | grep -q "go1\.2[7-9]" || { echo "FAIL: gosu not rebuilt"; exit 1; }
echo "PASS synapse $(docker exec "$name" python -c 'import synapse; print(synapse.__version__)') libpq $libpq"
