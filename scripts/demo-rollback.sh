#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
: "${BASE_URL:=http://localhost:8000}"
: "${1:?Usage: demo-rollback.sh vOLD vNEW}"
: "${2:?Usage: demo-rollback.sh vOLD vNEW}"
mkdir -p evidence
bash scripts/deploy.sh "$1"
curl --fail --silent --show-error -H 'Content-Type: application/json' -d '{"author":"rollback-demo","text":"This message must survive rollback"}' "$BASE_URL/messages"
for version in "$2" "$1"; do
  bash scripts/deploy.sh "$version"
  curl --fail --silent --show-error "$BASE_URL/ready" | tee "evidence/$version-ready.json"
  curl --fail --silent --show-error "$BASE_URL/" | python3 -c 'import json,sys; assert json.load(sys.stdin)["version"] == sys.argv[1].removeprefix("v")' "$version"
  curl --fail --silent --show-error "$BASE_URL/messages" | tee "evidence/$version-messages.json" | python3 -c 'import json,sys; assert {"author":"rollback-demo","text":"This message must survive rollback"} in json.load(sys.stdin)'
done
