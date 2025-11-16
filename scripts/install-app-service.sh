#!/usr/bin/env bash
# Instalar systemd unit para app Next.js standalone
# Ejecutar en el VPS como root:
#   bash install-app-service.sh
set -euo pipefail

APP_DIR=/opt/smarteros/app.smarterbot.cl
APP_USER=smarteros
PORT=3000

cat > /etc/systemd/system/smarteros-app.service <<EOF
[Unit]
Description=SmarterOS App (Next.js Standalone)
After=network.target

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
Environment=PORT=$PORT
Environment=HOSTNAME=0.0.0.0
Environment=NODE_ENV=production
ExecStart=/usr/bin/node .next/standalone/server.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable smarteros-app

echo "✅ Servicio smarteros-app instalado."
echo ""
echo "Comandos útiles:"
echo "   sudo systemctl start smarteros-app"
echo "   sudo systemctl status smarteros-app"
echo "   sudo journalctl -u smarteros-app -f"
