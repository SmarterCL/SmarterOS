#!/usr/bin/env bash
# Setup Vault CLI en Mac y conectar como admin
# Ejecutar en tu Mac:
#   bash setup-vault-mac.sh <vault_root_or_admin_token>
set -euo pipefail

TOKEN=${1:-}
if [[ -z "$TOKEN" ]]; then
  echo "Uso: $0 <vault_token>" >&2
  exit 1
fi

echo "==> Instalando Vault CLI (Homebrew)..."
if ! command -v vault >/dev/null; then
  brew tap hashicorp/tap
  brew install hashicorp/tap/vault
fi

echo "==> Configurando entorno..."
cat >> ~/.zshrc <<'EOF'

# Vault SmarterOS
export VAULT_ADDR="https://vault.smarterbot.cl"
EOF

source ~/.zshrc || true
export VAULT_ADDR="https://vault.smarterbot.cl"

echo "==> Login a Vault..."
vault login "$TOKEN"

echo "✅ Vault CLI configurado."
echo ""
echo "Ejemplos:"
echo "   vault kv get smarteros/ssh/deploy"
echo "   vault kv put smarteros/app/env-prod DATABASE_URL=postgres://..."
echo ""
echo "Recuperar clave deploy:"
echo "   vault kv get -field=private_key smarteros/ssh/deploy > ~/.ssh/id_rsa_smarteros"
echo "   chmod 600 ~/.ssh/id_rsa_smarteros"
