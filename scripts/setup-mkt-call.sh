#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "[1/4] Preparando directorios"
mkdir -p "$ROOT_DIR/front/mkt.smarterbot.cl" "$ROOT_DIR/services/call.smarterbot.cl"

echo "[2/4] Clonando repos si faltan"
if [ -z "$(ls -A "$ROOT_DIR/front/mkt.smarterbot.cl" 2>/dev/null || true)" ]; then
  git clone https://github.com/BlogBowl/BlogBowl "$ROOT_DIR/front/mkt.smarterbot.cl"
else
  echo "- Ya existe contenido en front/mkt.smarterbot.cl (omitido)"
fi

if [ -z "$(ls -A "$ROOT_DIR/services/call.smarterbot.cl" 2>/dev/null || true)" ]; then
  git clone https://github.com/microsoft/call-center-ai "$ROOT_DIR/services/call.smarterbot.cl"
else
  echo "- Ya existe contenido en services/call.smarterbot.cl (omitido)"
fi

echo "[3/4] Levantando contenedores (Traefik requerido en red dokploy-network)"
cd "$ROOT_DIR/dkcompose"
docker compose -f docker-compose.mkt-call.yml up -d --build

echo "[4/4] Listo. Endpoints esperados:"
echo "- https://mkt.smarterbot.cl"
echo "- https://call.smarterbot.cl"
