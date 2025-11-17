# mcp.smarterbot.cl (MCP Server mínimo)

Servicio HTTP mínimo que expone herramientas ("MCP tools") como endpoints REST y maneja webhooks desde Chatwoot.

- `POST /tools/google.contacts.lookup` → Busca contacto en Google Contacts (People API)
- `POST /webhook/chatwoot` → Recibe eventos de Chatwoot (message_created, conversation_created, etc.) con verificación HMAC

> Nota: Este servidor no implementa el wire del protocolo MCP-WebSocket; provee endpoints HTTP pensados para las automations de Chatwoot y para orquestación. Puedes envolverlo en un MCP formal más adelante si lo requieres.

## Zero-Trust (Vault + AppRole)

El servidor arranca con `.env` mínimo y obtiene secretos desde Vault en runtime usando AppRole.

**Flujo de bootstrapping:**
1. Al arrancar, `server.js` lee `VAULT_ADDR`, `VAULT_ROLE_ID`, `VAULT_SECRET_ID` del entorno.
2. Ejecuta `vaultLoginWithAppRole()` → obtiene token temporal (TTL 30m).
3. Lee secretos desde `secret/mcp/google-oauth`, `secret/mcp/chatwoot`, `secret/mcp/n8n`.
4. Cachea secretos en memoria (módulo `secrets.js`).
5. Refresca cache cada 10 minutos (token rotation automática).

**`.env` (mínimo):**
```
VAULT_ADDR=https://vault.smarterbot.cl
VAULT_ROLE_ID=...
VAULT_SECRET_ID=...
CHATWOOT_WEBHOOK_SECRET=...
PORT=3100
LOG_LEVEL=info
RAG_IDENTITY=smarterbotcl@gmail.com
```

**Secretos en Vault (KV v2):**
- `secret/mcp/google-oauth` → `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`, `GOOGLE_REDIRECT_URI=https://mcp.smarterbot.cl/oauth2/callback`
- `secret/mcp/chatwoot` → `CHATWOOT_API_TOKEN` (para usos futuros desde MCP)
- `secret/mcp/n8n` → `N8N_API_KEY`

**Configuración Vault (una vez):**
```bash
# 1. Crear política 'mcp'
vault policy write mcp - <<'HCL'
path "secret/data/mcp/*" {
  capabilities = ["read", "list"]
}
HCL

# 2. Habilitar AppRole
vault auth enable approle

# 3. Crear rol 'mcp' con TTL corto
vault write auth/approle/role/mcp \
  token_policies="mcp" \
  token_ttl=30m \
  token_max_ttl=2h

# 4. Obtener RoleID y SecretID
vault read -field=role_id auth/approle/role/mcp/role-id
vault write -field=secret_id -f auth/approle/role/mcp/secret-id

# 5. Cargar secretos (SOLO smarterbotcl@gmail.com)
vault kv put secret/mcp/google-oauth \
  GOOGLE_CLIENT_ID="..." \
  GOOGLE_CLIENT_SECRET="..." \
  GOOGLE_REFRESH_TOKEN="..." \
  GOOGLE_REDIRECT_URI="https://mcp.smarterbot.cl/oauth2/callback"

vault kv put secret/mcp/chatwoot CHATWOOT_API_TOKEN="..."
vault kv put secret/mcp/n8n N8N_API_KEY="..."
```

**Ventajas:**
- ✅ Sin credenciales de Google en código ni en GitHub.
- ✅ Rotación de tokens automática (cada 30m, máx 2h).
- ✅ Un solo `REFRESH_TOKEN` asociado a `smarterbotcl@gmail.com` → no requiere "permitir" en cada deploy.
- ✅ RAG_IDENTITY auditable en logs con tag `[RAG-AUDIT:SMARTERBOTCL]`.

## Uso local

```bash
cd services/mcp.smarterbot.cl
cp .env.example .env
pnpm i --ignore-scripts
pnpm dev
# GET http://localhost:3100/health → { status: 'ok', service: 'mcp-smarterbot' }
```

Probar tool:
```bash
curl -s -X POST http://localhost:3100/tools/google.contacts.lookup \
  -H 'Content-Type: application/json' \
  -d '{ "email": "juan@example.com" }' | jq
```

## Seguridad Webhook (Chatwoot → MCP)

**HMAC-SHA256 verification:**
- Configura `CHATWOOT_WEBHOOK_SECRET` en `.env` del MCP (no en Git).
- Usa el mismo secret en Chatwoot: Settings → Integrations → Webhooks → Add Webhook → Secret.
- Chatwoot firma el body con HMAC-SHA256 y envía en header `X-Chatwoot-Signature`.
- MCP valida firma en `verifyChatwootHmac()` middleware antes de procesar.
- Si falta header o firma no coincide → 401 Unauthorized.

**Configurar en Chatwoot:**
1. Settings → Integrations → Webhooks → Add Webhook
2. Name: `SmarterOS`
3. URL: `https://mcp.smarterbot.cl/webhook/chatwoot`
4. Secret: mismo valor que `CHATWOOT_WEBHOOK_SECRET` en `.env`
5. Events: `message_created`, `conversation_created`, `contact_updated`, `conversation_status_changed`
6. Save

**Log de auditoría:**
- Todos los eventos incluyen tag `[RAG-AUDIT:SMARTERBOTCL]` y `ragIdentity: smarterbotcl@gmail.com` para RAG compliance.

## Despliegue en VPS (Dokploy)
- Compose: `dkcompose/mcp.smarterbot.cl.yml` (Traefik + TLS, redes pública/interna)
- Deploy: `scripts/smos deploy mcp`

## Chatwoot Automations
Importa `docs/chatwoot-smarteros-automation.json`.

- Enriquecimiento Google Contacts al crear conversación (WhatsApp)
- Clasificación de intención (placeholder)
- Respuesta de bienvenida (tenant)
