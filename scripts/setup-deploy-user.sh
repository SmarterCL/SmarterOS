#!/usr/bin/env bash
# ONE-COMMAND: crear usuario smarteros con clave restringida rsync-only
# Ejecutar en el VPS como root:
#   bash setup-deploy-user.sh
set -euo pipefail

DEPLOY_USER=smarteros
DEPLOY_DIR=/opt/smarteros
PUBKEY_PATH=${1:-}

echo "==> Creando usuario $DEPLOY_USER..."
if ! id -u "$DEPLOY_USER" >/dev/null 2>&1; then
  adduser --disabled-password --gecos "SmarterOS Deploy User" "$DEPLOY_USER"
  usermod -s /usr/sbin/nologin "$DEPLOY_USER"
fi

echo "==> Creando directorio de deploy $DEPLOY_DIR..."
mkdir -p "$DEPLOY_DIR"
chown -R "$DEPLOY_USER":"$DEPLOY_USER" "$DEPLOY_DIR"
chmod 755 "$DEPLOY_DIR"

echo "==> Configurando SSH..."
mkdir -p "/home/$DEPLOY_USER/.ssh"
chown "$DEPLOY_USER":"$DEPLOY_USER" "/home/$DEPLOY_USER/.ssh"
chmod 700 "/home/$DEPLOY_USER/.ssh"

if [[ -n "$PUBKEY_PATH" ]] && [[ -f "$PUBKEY_PATH" ]]; then
  PUBKEY=$(cat "$PUBKEY_PATH")
  AK="/home/$DEPLOY_USER/.ssh/authorized_keys"
  
  # Restricción completa: solo rsync server, sin shell, sin forwarding
  echo "command=\"/usr/local/bin/rsync-wrapper\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty $PUBKEY" > "$AK"
  chown "$DEPLOY_USER":"$DEPLOY_USER" "$AK"
  chmod 600 "$AK"
  
  echo "==> Clave pública instalada con restricciones."
else
  echo "⚠ No se proporcionó clave pública. Agrégala manualmente a /home/$DEPLOY_USER/.ssh/authorized_keys"
fi

# Wrapper rsync que valida comandos
cat > /usr/local/bin/rsync-wrapper <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ALLOWED_BASE=/opt/smarteros
CMD=${SSH_ORIGINAL_COMMAND:-}
if [[ -z "$CMD" ]]; then
  echo "No shell access." >&2
  exit 1
fi
if [[ "$CMD" != rsync\ --server* ]]; then
  echo "Only rsync allowed." >&2
  exit 1
fi
cd "$ALLOWED_BASE"
exec $CMD
EOF
chmod 755 /usr/local/bin/rsync-wrapper

echo "✅ Usuario $DEPLOY_USER listo:"
echo "   - Shell: nologin"
echo "   - Deploy dir: $DEPLOY_DIR"
echo "   - SSH: solo rsync"
echo ""
echo "Prueba desde tu Mac:"
echo "   rsync -az -e 'ssh -i ~/.ssh/id_rsa_smarteros' /tmp/test.txt $DEPLOY_USER@\$(hostname -I | awk '{print \$1}'):$DEPLOY_DIR/"
