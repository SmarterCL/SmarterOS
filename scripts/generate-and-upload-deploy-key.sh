#!/usr/bin/env bash
# Generar clave deploy y subirla a Vault
# Ejecutar en tu Mac:
#   bash generate-and-upload-deploy-key.sh
set -euo pipefail

KEY_PATH=~/.ssh/id_rsa_smarteros

if [[ ! -f "$KEY_PATH" ]]; then
  echo "==> Generando nueva clave deploy ed25519..."
  ssh-keygen -t ed25519 -f "$KEY_PATH" -C "deploy-smarteros" -N ""
else
  echo "==> Clave existente detectada: $KEY_PATH"
fi

echo "==> Subiendo a Vault..."
export VAULT_ADDR="https://vault.smarterbot.cl"
vault kv put smarteros/ssh/deploy \
  private_key="$(cat $KEY_PATH)" \
  public_key="$(cat ${KEY_PATH}.pub)"

echo "✅ Clave subida a Vault: smarteros/ssh/deploy"
echo ""
echo "Clave pública (para instalar en el VPS):"
cat "${KEY_PATH}.pub"
echo ""
echo "Copia esta clave y ejecuta en el VPS:"
echo "   echo '<clave_pública>' | bash setup-deploy-user.sh /dev/stdin"
