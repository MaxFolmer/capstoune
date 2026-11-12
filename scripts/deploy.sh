#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ ${1:-} =~ ^v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]] || { echo 'Usage: bash scripts/deploy.sh vX.Y.Z'; exit 2; }
export IMAGE_TAG="$1"
mkdir -p evidence
# Pull before touching the running service. Database volume is never removed.
docker compose -p guestbook-prod -f compose.prod.yaml pull app
docker compose -p guestbook-prod -f compose.prod.yaml up -d --wait --wait-timeout 120
printf '%s %s\n' "$(date -u +%FT%TZ)" "$IMAGE_TAG" >> evidence/deployments.log
docker compose -p guestbook-prod -f compose.prod.yaml ps
