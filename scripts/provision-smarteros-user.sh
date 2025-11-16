#!/usr/bin/env bash
# Provee un usuario restringido 'smarteros' para despliegues vía rsync.
# Ejecutar en el VPS como root:
#   curl -fsSL https://example.com/provision.sh | bash -s -- "ssh-rsa AAAA..."
# O bien copiar este archivo y ejecutar:
#   DEPLOY_PUBKEY="ssh-ed25519 AAAA..." bash provision-smarteros-user.sh
set -euo pipefail

PUBKEY=${1:-${DEPLOY_PUBKEY:-}}
DEPLOY_USER=${DEPLOY_USER:-smarteros}
DEPLOY_DIR=${DEPLOY_DIR:-/opt/smarteros}

if [[ -z "$PUBKEY" ]]; then
  echo "Falta clave pública (argumento 1 o variable DEPLOY_PUBKEY)." >&2
  exit 1
fi

# Crear usuario si no existe
if ! id -u "$DEPLOY_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$DEPLOY_USER"
fi

# Crear directorio de despliegue y asignar permisos
mkdir -p "$DEPLOY_DIR"
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$DEPLOY_DIR"
chmod 755 "$DEPLOY_DIR"

# Instalar wrapper de rsync restringido
WRAPPER=/usr/local/bin/rsync-serve-smarteros
cat > "$WRAPPER" <<'EOF'
#!/usr/bin/env bash
# Wrapper para permitir solo rsync --server en una ruta específica.
set -euo pipefail
ALLOWED_BASE=${ALLOWED_BASE:-/opt/smarteros}
CMD=${SSH_ORIGINAL_COMMAND:-}
if [[ -z "$CMD" ]]; then
  echo "Comando vacío." >&2
  exit 1
fi
# Permitir solo rsync server
if [[ "$CMD" != rsync\ --server* ]]; then
  echo "Comando no permitido." >&2
  exit 1
fi
# Ejecutar como shell - rsync validará rutas; reforzar PWD
cd "$ALLOWED_BASE"
exec $CMD
EOF
chmod 755 "$WRAPPER"

# Configurar authorized_keys con restricciones
install -d -m 700 "/home/$DEPLOY_USER/.ssh" -o "$DEPLOY_USER" -g "$DEPLOY_USER"
AK="/home/$DEPLOY_USER/.ssh/authorized_keys"
TO_ADD="command=\"ALLOWED_BASE=$DEPLOY_DIR $WRAPPER\",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding $PUBKEY"
if [[ -f "$AK" ]] && grep -q "$PUBKEY" "$AK"; then
  echo "Clave ya presente en authorized_keys"
else
  echo "$TO_ADD" >> "$AK"
  chown "$DEPLOY_USER":"$DEPLOY_USER" "$AK"
  chmod 600 "$AK"
fi

# Mostrar resumen
cat <<INFO
Usuario listo:
  user: $DEPLOY_USER
  dir:  $DEPLOY_DIR
Wrapper:
  $WRAPPER
Recuerda usar esta clave PRIVADA en GitHub Secret como SMARTEROS_RSYNC_KEY.
INFO
