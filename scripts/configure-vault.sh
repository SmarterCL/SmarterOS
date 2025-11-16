#!/usr/bin/env bash
# Configurar Vault después de init
# Ejecutar en el VPS tras vault operator init:
#   bash configure-vault.sh <root_token>
set -euo pipefail

ROOT_TOKEN=${1:-}
if [[ -z "$ROOT_TOKEN" ]]; then
  echo "Uso: $0 <root_token>" >&2
  exit 1
fi

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=$ROOT_TOKEN

echo "==> Unsealing Vault (requiere 3 de 5 claves)..."
echo "Ejecuta manualmente:"
echo "   vault operator unseal"
echo "(3 veces con claves distintas)"
echo ""
read -p "Presiona Enter cuando Vault esté unsealed..."

echo "==> Habilitando motor KV v2 en /smarteros..."
vault secrets enable -path=smarteros kv-v2

echo "==> Creando política de lectura para CI/CD..."
cat > /tmp/ci-policy.hcl <<EOF
path "smarteros/data/ssh/*" {
  capabilities = ["read"]
}
path "smarteros/data/app/*" {
  capabilities = ["read"]
}
path "smarteros/data/mcp/*" {
  capabilities = ["read"]
}
EOF
vault policy write ci-readonly /tmp/ci-policy.hcl
rm /tmp/ci-policy.hcl

echo "==> Habilitando JWT auth para GitHub Actions..."
vault auth enable jwt

vault write auth/jwt/config \
  bound_issuer="https://token.actions.githubusercontent.com" \
  oidc_discovery_url="https://token.actions.githubusercontent.com"

vault write auth/jwt/role/github-actions \
  role_type="jwt" \
  bound_audiences="vault" \
  user_claim="actor" \
  bound_claims='{"repository":"SmarterCL/app.smarterbot.cl"}' \
  policies="ci-readonly" \
  ttl="10m"

echo "✅ Vault configurado:"
echo "   - Motor KV: smarteros/"
echo "   - Auth JWT: github-actions role"
echo "   - Policy: ci-readonly"
echo ""
echo "Sube claves:"
echo "   vault kv put smarteros/ssh/deploy private_key=@~/.ssh/id_rsa_smarteros public_key=@~/.ssh/id_rsa_smarteros.pub"
