#!/usr/bin/env bash
# Instalar Vault OSS en el VPS
# Ejecutar como root:
#   bash install-vault.sh
set -euo pipefail

VAULT_VERSION=1.18.1
VAULT_DIR=/opt/vault
VAULT_CONFIG_DIR=$VAULT_DIR/config
VAULT_DATA_DIR=$VAULT_DIR/data
VAULT_LOG=/var/log/vault

echo "==> Instalando Vault OSS v$VAULT_VERSION..."
apt update && apt install -y unzip curl
curl -fsSL "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" -o /tmp/vault.zip
unzip -o /tmp/vault.zip -d /usr/local/bin/
chmod +x /usr/local/bin/vault
rm /tmp/vault.zip
vault --version

echo "==> Creando estructura de directorios..."
mkdir -p "$VAULT_CONFIG_DIR" "$VAULT_DATA_DIR" "$VAULT_LOG"
if ! id -u vault >/dev/null 2>&1; then
  useradd --system --home "$VAULT_DIR" --shell /bin/false vault
fi
chown -R vault:vault "$VAULT_DIR" "$VAULT_LOG"

echo "==> Generando config.hcl..."
cat > "$VAULT_CONFIG_DIR/config.hcl" <<EOF
ui = true

storage "file" {
  path = "$VAULT_DATA_DIR"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

disable_mlock = true

api_addr = "https://vault.smarterbot.cl"
cluster_addr = "https://vault.smarterbot.cl"
EOF

echo "==> Creando systemd unit..."
cat > /etc/systemd/system/vault.service <<EOF
[Unit]
Description=Vault OSS
After=network.target

[Service]
User=vault
Group=vault
ExecStart=/usr/local/bin/vault server -config=$VAULT_CONFIG_DIR/config.hcl
ExecReload=/bin/kill --signal HUP \$MAINPID
Restart=always
LimitMEMLOCK=infinity

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable vault
systemctl start vault

echo "✅ Vault instalado y activo."
echo ""
echo "Siguiente paso: inicializar Vault"
echo "   export VAULT_ADDR=http://127.0.0.1:8200"
echo "   vault operator init"
echo ""
echo "Guarda las 5 unseal keys y el root token de forma segura."
