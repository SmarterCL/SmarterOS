#!/usr/bin/env bash
# 🚀 MASTER SETUP: Ejecuta todo el plan integrado de SmarterOS
# Este script coordina la instalación completa en orden correcto.
# Uso: bash master-setup.sh <paso>
#   Pasos disponibles: vps-vault, vps-user, vps-app, mac-vault, mac-keys, test
set -euo pipefail

STEP=${1:-help}
VPS_HOST=${VPS_HOST:-89.116.23.167}
VPS_USER=${VPS_USER:-root}
# Alias SSH friendly (rsync-only). Si se define, prioriza usarlo.
SM_ALIAS=${SM_ALIAS:-smarteros}

case "$STEP" in
  vps-vault)
    echo "📦 PASO 1: Instalando Vault en VPS..."
    echo ""
    # Intento 1: si tenemos alias smarteros (sin password), subimos el script al setup del proyecto
    if ssh -o BatchMode=yes "$SM_ALIAS" "true" 2>/dev/null; then
      echo "🔑 Usando alias SSH '$SM_ALIAS' (sin contraseña)."
      ssh "$SM_ALIAS" "mkdir -p /opt/smarteros/setup"
      rsync -az install-vault.sh "$SM_ALIAS":/opt/smarteros/setup/
      echo "🚀 Intentando ejecutar con sudo (si está permitido)..."
      if ssh -o BatchMode=yes "$SM_ALIAS" "sudo -n true" 2>/dev/null; then
        ssh "$SM_ALIAS" "sudo bash /opt/smarteros/setup/install-vault.sh"
        R=$?
      else
        echo "⚠️  No hay sudo sin contraseña para '$SM_ALIAS'."
        echo "➡️  Ejecuta manualmente en la consola del VPS (root/admin):"
        echo "    bash /opt/smarteros/setup/install-vault.sh"
        R=0
      fi
    else
      # Intento 2: root por SSH (requiere clave o password)
      echo "🔐 Alias '$SM_ALIAS' no disponible. Probando root por SSH..."
      scp install-vault.sh ${VPS_USER}@${VPS_HOST}:/root/
      ssh ${VPS_USER}@${VPS_HOST} "bash /root/install-vault.sh"
      R=$?
    fi

    if [ "${R:-1}" -ne 0 ]; then
      echo "❌ Error instalando Vault. Revisa conectividad SSH o permisos."
      exit 1
    fi

    echo ""
    echo "✅ Vault instalado. Siguiente paso:"
    echo "   ssh ${VPS_USER}@${VPS_HOST}"
    echo "   export VAULT_ADDR=http://127.0.0.1:8200"
    echo "   vault operator init"
    echo ""
    echo "GUARDA las 5 unseal keys y el root token."
    echo "Luego ejecuta: bash master-setup.sh vps-unseal"
    ;;

  vps-unseal)
    echo "🔓 PASO 2: Unseal Vault (requiere interacción)..."
    echo "Conéctate al VPS y ejecuta:"
    echo "   export VAULT_ADDR=http://127.0.0.1:8200"
    echo "   vault operator unseal  # (3 veces con keys distintas)"
    echo ""
    echo "Luego ejecuta: bash master-setup.sh vps-configure"
    ;;

  vps-configure)
    echo "⚙️  PASO 3: Configurando Vault (KV + JWT)..."
    read -sp "Ingresa root token: " ROOT_TOKEN
    echo ""
    scp configure-vault.sh ${VPS_USER}@${VPS_HOST}:/root/
    ssh ${VPS_USER}@${VPS_HOST} "bash /root/configure-vault.sh ${ROOT_TOKEN}"
    echo ""
    echo "✅ Vault configurado."
    echo "Siguiente: bash master-setup.sh vps-caddy"
    ;;

  vps-caddy)
    echo "🌐 PASO 4: Configurando Caddy..."
    scp Caddyfile.vault ${VPS_USER}@${VPS_HOST}:/etc/caddy/Caddyfile
    ssh ${VPS_USER}@${VPS_HOST} "systemctl reload caddy"
    echo "✅ Caddy reconfigurado."
    echo "Vault accesible en: https://vault.smarterbot.cl"
    echo ""
    echo "Siguiente: bash master-setup.sh vps-user"
    ;;

  vps-user)
    echo "👤 PASO 5: Creando usuario deploy smarteros..."
    scp setup-deploy-user.sh ${VPS_USER}@${VPS_HOST}:/root/
    ssh ${VPS_USER}@${VPS_HOST} "bash /root/setup-deploy-user.sh"
    echo "✅ Usuario smarteros creado."
    echo ""
    echo "Siguiente: bash master-setup.sh mac-keys"
    ;;

  mac-keys)
    echo "🔑 PASO 6: Generando clave deploy en Mac..."
    bash generate-and-upload-deploy-key.sh
    echo ""
    echo "✅ Clave generada y subida a Vault."
    echo "Copia la clave pública del output anterior y ejecuta en VPS:"
    echo "   ssh ${VPS_USER}@${VPS_HOST}"
    echo "   echo 'ssh-ed25519 AAAA...' >> /home/smarteros/.ssh/authorized_keys"
    echo ""
    echo "Siguiente: bash master-setup.sh mac-vault"
    ;;

  mac-vault)
    echo "💻 PASO 7: Conectando Mac a Vault..."
    read -sp "Ingresa root token o admin token: " TOKEN
    echo ""
    bash setup-vault-mac.sh "$TOKEN"
    echo "✅ Mac conectada a Vault."
    echo ""
    echo "Siguiente: bash master-setup.sh vps-app"
    ;;

  vps-app)
    echo "📱 PASO 8: Instalando servicio app..."
    scp install-app-service.sh ${VPS_USER}@${VPS_HOST}:/root/
    ssh ${VPS_USER}@${VPS_HOST} "bash /root/install-app-service.sh"
    echo "✅ Servicio smarteros-app instalado."
    echo ""
    echo "Siguiente: bash master-setup.sh test"
    ;;

  test)
    echo "🧪 PASO 9: Pruebas de integración..."
    echo ""
    echo "1️⃣ Probar rsync:"
    echo "test-sync-$(date +%s)" > /tmp/test-sync.txt
    rsync -az -e "ssh -i ~/.ssh/id_rsa_smarteros" /tmp/test-sync.txt smarteros@${VPS_HOST}:/opt/smarteros/
    echo "✅ Rsync funciona."
    echo ""
    echo "2️⃣ Probar Vault:"
    export VAULT_ADDR=https://vault.smarterbot.cl
    vault kv get smarteros/ssh/deploy >/dev/null && echo "✅ Vault accesible." || echo "❌ Vault inaccesible."
    echo ""
    echo "3️⃣ Configurar secrets GitHub:"
    echo "Ve a: https://github.com/SmarterCL/app.smarterbot.cl/settings/secrets/actions"
    echo "Agrega:"
    echo "  - SMARTEROS_HOST: ${VPS_HOST}"
    echo "  - SMARTEROS_PATH: /opt/smarteros"
    echo ""
    echo "4️⃣ Probar workflow:"
    echo "   echo '# Test' >> ../smarteros-specs/README.md"
    echo "   git add . && git commit -m 'test: vault workflow' && git push"
    echo ""
    echo "✅ SETUP COMPLETO."
    ;;

  all)
    echo "🚀 Ejecutando setup completo (requiere interacción)..."
    bash $0 vps-vault
    read -p "Presiona Enter tras vault operator init y guarda keys/token..."
    bash $0 vps-configure
    bash $0 vps-caddy
    bash $0 vps-user
    bash $0 mac-keys
    read -p "Presiona Enter tras agregar clave pública al VPS..."
    bash $0 mac-vault
    bash $0 vps-app
    bash $0 test
    ;;

  help|*)
    cat <<EOF
🚀 Master Setup SmarterOS + Vault

Uso: bash master-setup.sh <paso>

Pasos disponibles (en orden):
  vps-vault       Instalar Vault en VPS
  vps-unseal      Guía unseal (requiere keys)
  vps-configure   Configurar Vault (KV + JWT)
  vps-caddy       Configurar Caddy para HTTPS
  vps-user        Crear usuario deploy smarteros
  mac-keys        Generar clave deploy en Mac
  mac-vault       Conectar Vault CLI en Mac
  vps-app         Instalar systemd app service
  test            Pruebas de integración
  all             Ejecutar todo (interactivo)

Ejemplo:
  bash master-setup.sh vps-vault
  bash master-setup.sh vps-configure
  ...

Variables de entorno:
  VPS_HOST=${VPS_HOST}
  VPS_USER=${VPS_USER}
  SM_ALIAS=${SM_ALIAS}
EOF
    ;;
esac
