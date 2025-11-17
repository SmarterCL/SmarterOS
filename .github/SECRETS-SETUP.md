# 🔐 GitHub Actions Secrets Setup
**Repositorio:** SmarterCL/SmarterOS

## Secrets Requeridos

### ✅ Existente
- `SMARTERVAULT` - *Ya configurado*

### ⚠️ Faltantes para Workflow de Backup

#### 1. `VAULT_ADDR`
**Descripción:** URL del servidor Vault  
**Valor:** URL completa de tu servidor Vault

**Ejemplos:**
```bash
# Si es Vault local/VPS
https://vault.smarterbot.cl

# Si es HashiCorp Cloud Platform (HCP)
https://smarteros-vault.vault.XXXX.hashicorp.cloud:8200

# Si es localhost (solo para desarrollo)
http://127.0.0.1:8200
```

#### 2. `VAULT_TOKEN`
**Descripción:** Token de autenticación para Vault  
**Valor:** Token con política `ci-readonly` o similar

**Obtener token:**
```bash
# Opción A: Token root (solo desarrollo)
vault token create -policy=ci-readonly -ttl=720h

# Opción B: AppRole (producción recomendado)
vault write auth/approle/role/github-actions/secret-id -format=json

# Opción C: Ver token actual de SMARTERVAULT
echo $SMARTERVAULT | base64 -d
```

---

## 📋 Pasos para Configurar

### 1. Ir a GitHub Settings
```
https://github.com/SmarterCL/SmarterOS/settings/secrets/actions
```

### 2. Agregar `VAULT_ADDR`
1. Click **"New repository secret"**
2. Name: `VAULT_ADDR`
3. Secret: `https://vault.smarterbot.cl` *(tu URL real)*
4. Click **"Add secret"**

### 3. Agregar `VAULT_TOKEN`
1. Click **"New repository secret"**
2. Name: `VAULT_TOKEN`
3. Secret: `hvs.XXXXXXXXXXXX` *(tu token de Vault)*
4. Click **"Add secret"**

### 4. Verificar Configuración
Una vez agregados, deberías ver:
```
✅ SMARTERVAULT
✅ VAULT_ADDR
✅ VAULT_TOKEN
```

---

## 🔧 Opción Alternativa: Usar SMARTERVAULT

Si `SMARTERVAULT` ya contiene toda la info necesaria:

### Detectar formato actual
```bash
# Ver si es JSON
echo $SMARTERVAULT | base64 -d | jq .

# Ver si es formato "addr:token"
echo $SMARTERVAULT | base64 -d
```

### Modificar workflow para extraer
Si `SMARTERVAULT` es formato `{"addr": "...", "token": "..."}`:

```yaml
env:
  VAULT_DATA: ${{ secrets.SMARTERVAULT }}

- name: Parse Vault Credentials
  run: |
    VAULT_ADDR=$(echo "$VAULT_DATA" | jq -r '.addr')
    VAULT_TOKEN=$(echo "$VAULT_DATA" | jq -r '.token')
    echo "VAULT_ADDR=$VAULT_ADDR" >> $GITHUB_ENV
    echo "VAULT_TOKEN=$VAULT_TOKEN" >> $GITHUB_ENV
```

---

## 🧪 Probar Workflow

Después de configurar los secrets:

### Via GitHub UI
```
Actions → Backup VPS Diario → Run workflow → Run workflow
```

### Via GitHub CLI
```bash
gh workflow run backup-vps-daily.yml
```

### Verificar logs
```bash
gh run list --workflow=backup-vps-daily.yml
gh run view [RUN_ID] --log
```

---

## 📊 Secrets Adicionales (Futuro)

Para workflows futuros, considera agregar:

### Slack Notifications
- `SLACK_BOT_TOKEN` - Para notificaciones en #ops

### N8N Webhooks
- `N8N_WEBHOOK_SECRET` - Validar llamadas desde GitHub

### Clerk (si necesitas keys en CI)
- `CLERK_SECRET_KEY` - Para tests de integración

---

## 🔒 Seguridad

### Buenas Prácticas
1. ✅ Usa tokens con permisos mínimos (least privilege)
2. ✅ Configura TTL en tokens (`-ttl=720h` = 30 días)
3. ✅ Rota secrets periódicamente
4. ✅ No commitees secrets en código
5. ✅ Usa `echo "::add-mask::$SECRET"` para ocultar en logs

### Políticas Vault Recomendadas
```hcl
# vault/policies/ci-readonly.hcl
path "smarteros/mcp/*" {
  capabilities = ["read", "list"]
}

path "smarteros/backups/*" {
  capabilities = ["create", "read", "update", "list"]
}
```

---

## ❓ Troubleshooting

### Error: "VAULT_ADDR not set"
- Verifica que el secret existe en GitHub Settings
- Revisa mayúsculas/minúsculas del nombre

### Error: "Permission denied"
- Token no tiene política correcta
- Crear nuevo token con `ci-readonly` policy

### Error: "Connection refused"
- VAULT_ADDR incorrecta
- Firewall bloqueando puerto 8200

---

**Última actualización:** 17 Nov 2025  
**Próximo paso:** Agregar secrets → Re-enable cron schedule en workflow
