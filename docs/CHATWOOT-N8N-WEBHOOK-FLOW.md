# Chatwoot ↔ n8n Webhook Integration Flow

**Versión:** 1.0  
**Última actualización:** 2025-11-17  
**Repositorios:**
- `app.smarterbot.cl` - Dashboard con configuración webhook
- `n8n-smarteros` - n8n deployment en Azure ACA
- `smarteros-specs/docs` - Documentación arquitectura

---

## 📋 Contexto

Integración bidireccional entre **Chatwoot** (inbox multi-canal) y **n8n** (workflow automation) para:

1. **OCR inteligente** de imágenes enviadas por WhatsApp/Email → clasificación con LLM → respuesta automática
2. **Sincronización de contactos** entre Dashboard → Supabase → Chatwoot → Odoo
3. **Automatizaciones custom** definidas en n8n y ejecutadas por eventos de Chatwoot

**Stack:**
- **Chatwoot:** `chatwoot.smarterbot.cl` (multi-tenant, cada tenant tiene su propio `inbox_id` y `account_id`)
- **n8n:** `n8n.smarterbot.cl` (Azure Container Apps, Postgres backend, autenticación con Vault)
- **MCP Service:** `mcp.smarterbot.cl` (intermediario para operaciones complejas, autenticación HMAC)
- **Dashboard:** `app.smarterbot.cl/settings` (configuración webhook_url por tenant)

---

## 🔄 Flujo 1: Chatwoot → n8n (Webhook Events)

### Configuración en Chatwoot

Cada **inbox** en Chatwoot tiene un **webhook URL** configurable:

```
Settings → Inboxes → [Seleccionar Inbox] → Webhook
```

**Webhook URL:** `https://n8n.smarterbot.cl/webhook/chatwoot-events`

**Events suscritos:**
- `message_created` - Mensaje recibido (incoming)
- `conversation_created` - Nueva conversación iniciada
- `conversation_status_changed` - Conversación abierta/cerrada
- `conversation_updated` - Metadatos actualizados (etiquetas, custom attributes)

**Headers enviados por Chatwoot:**
```http
POST /webhook/chatwoot-events HTTP/1.1
Host: n8n.smarterbot.cl
Content-Type: application/json
X-Chatwoot-Event: message_created
X-Chatwoot-Signature: sha256=abc123...  (HMAC-SHA256 del payload)
```

**Payload ejemplo (message_created con attachment):**
```json
{
  "event": "message_created",
  "id": 98765,
  "conversation": {
    "id": 12345,
    "inbox_id": 101,
    "status": "open",
    "custom_attributes": {
      "rut": "12345678-9",
      "tenant_inbox": "tenant-12345678-9"
    }
  },
  "message": {
    "id": 543210,
    "content": "Hola, adjunto mi factura",
    "message_type": 0,
    "created_at": 1700227200,
    "attachments": [
      {
        "id": 789,
        "file_type": "image/jpeg",
        "data_url": "https://chatwoot.smarterbot.cl/rails/active_storage/blobs/...",
        "extension": "jpg"
      }
    ],
    "sender": {
      "id": 5678,
      "name": "Juan Pérez",
      "email": "juan@empresa.cl",
      "phone_number": "+56912345678",
      "type": "contact"
    }
  },
  "account": {
    "id": 1,
    "name": "SmarterBot"
  }
}
```

### n8n Workflow (Webhook Node)

**Workflow:** `Chatwoot → n8n OCR + Classify` (basado en `docs/n8n-workflow-ocr-classify.md`)

**Node 1: Webhook Trigger**
```yaml
Type: n8n-nodes-base.webhook
Path: /chatwoot-events
Method: POST
Auth: HMAC-SHA256 (secret from Vault: secret/n8n/chatwoot/hmac_secret)
Response Mode: On workflow finish
```

**Validación HMAC:**
```javascript
// Code Node - Validate HMAC
const crypto = require('crypto');
const payload = JSON.stringify($json);
const signature = $node["Webhook"].headers["x-chatwoot-signature"];
const secret = process.env.CHATWOOT_HMAC_SECRET; // From Vault

const expectedSignature = 'sha256=' + crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('hex');

if (signature !== expectedSignature) {
  throw new Error('Invalid HMAC signature');
}

return $json;
```

**Node 2: IF - Has Image Attachment**
```javascript
// Condition
$json.message.attachments?.length > 0 && 
$json.message.attachments[0].file_type.startsWith('image/')
```

**True branch:** Continuar con OCR workflow (nodes 3-12 según `n8n-workflow-ocr-classify.md`)  
**False branch:** Responder con mensaje estándar (o skip)

### Flujo OCR (Resumen)

1. **Download image** (HTTP Request node)
2. **Classify document type** (IF node: factura/form → Document AI, simple → Vision API, ambiguous → Gemini Vision)
3. **Extract text** con el método seleccionado
4. **Classify intent** (IF node: >500 chars → Gemini LLM, else → keyword matching)
5. **Update conversation** custom_attributes via MCP (`mcp.smarterbot.cl/tools/chatwoot.update_conversation`)
6. **Send response** to Chatwoot (`POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/messages`)
7. **Audit log** to Redpanda (`smarteros.audit.ocr` topic)

**Credenciales en n8n (desde Vault):**
- `GOOGLE_SERVICE_ACCOUNT_JSON` - Service Account con permisos Vision API + Document AI + Gemini
- `CHATWOOT_API_TOKEN` - Token de Chatwoot account (scope: conversations, messages, contacts)
- `CHATWOOT_HMAC_SECRET` - Para validar webhooks entrantes
- `MCP_BASE_URL` + `MCP_HMAC_SECRET` - Para llamar a MCP service
- `REDPANDA_API_TOKEN` - Para enviar eventos de auditoría

---

## 🔄 Flujo 2: Dashboard → Chatwoot (Sync Contacts)

### Configuración en Dashboard

**URL:** `https://app.smarterbot.cl/settings`

**Campos:**
- **Nombre del negocio:** metadata para identificar tenant
- **Webhook URL:** `https://n8n.smarterbot.cl/webhook/dashboard-sync` (configurable por tenant)

**Flujo:**
1. Usuario crea/edita contacto en `app.smarterbot.cl/dashboard`
2. Se guarda en **Supabase** tabla `contacts` con `clerk_user_id` y `rut`
3. Trigger automático (Supabase function o webhook) envía POST a `webhook_url` configurado
4. n8n recibe evento y ejecuta workflow `MCP - Sync Contact`

### n8n Workflow (MCP Sync Contact)

**Workflow:** `assets/workflows/mcp-sync-contact.json`

**Flujo:**
1. **Webhook Trigger** recibe payload del dashboard
2. **Query Supabase** - Obtener datos completos del contacto + tenant profile
3. **Code Node** - Consolidar contexto:
   ```javascript
   {
     rut: "12345678-9",
     user_id: "clerk_user_abc123",
     company_name: "Empresa Demo",
     chatwoot_account_id: "1",
     chatwoot_inbox_id: "101",
     contact: {
       name: "Juan Pérez",
       email: "juan@empresa.cl",
       phone: "+56912345678",
       source: "dashboard"
     }
   }
   ```
4. **Upsert Odoo** - Crear/actualizar partner en Odoo (optional)
5. **Upsert Chatwoot Contact** - `POST /api/v1/accounts/{account_id}/contacts`
   ```json
   {
     "identifier": "clerk_user_abc123",
     "name": "Juan Pérez",
     "email": "juan@empresa.cl",
     "phone_number": "+56912345678",
     "inbox_id": 101,
     "custom_attributes": {
       "rut": "12345678-9",
       "tenant_inbox": "tenant-12345678-9",
       "odoo_partner_id": 456
     }
   }
   ```
6. **Update Supabase** - Guardar `chatwoot_contact_id` en tabla `contacts`
7. **Respond** - HTTP 200 con metadata de sincronización
8. **Audit log** - Redpanda (`smarteros.audit.sync` topic)

**Credenciales:**
- `CHATWOOT_BASE_URL` - `https://chatwoot.smarterbot.cl`
- `CHATWOOT_API_TOKEN` - Token con permisos en account
- `SUPABASE_URL` + `SUPABASE_SERVICE_KEY` - Para queries directos
- `ODOO_URL` + `ODOO_API_KEY` - Si integración Odoo activa

---

## 🔄 Flujo 3: n8n → Chatwoot (Send Messages)

### Use Case: Respuesta automática post-OCR

Después de extraer texto y clasificar intent, n8n envía respuesta a Chatwoot.

**HTTP Request Node:**
```yaml
Method: POST
URL: https://chatwoot.smarterbot.cl/api/v1/accounts/{{$json.account_id}}/conversations/{{$json.conversation_id}}/messages
Headers:
  - api_access_token: {{$env.CHATWOOT_API_TOKEN}}
Body:
  {
    "content": "✅ Factura procesada. Detecté:\n- Monto: ${{ $json.ocr_amount }}\n- Fecha: {{ $json.ocr_date }}\n- Intent: {{ $json.intent }}\n\nMétodo OCR: {{ $json.ocr_method }}",
    "message_type": "outgoing",
    "private": false
  }
```

**Response esperado:**
```json
{
  "id": 654321,
  "content": "✅ Factura procesada...",
  "message_type": 1,
  "created_at": 1700227300,
  "conversation_id": 12345,
  "sender": {
    "id": 1,
    "name": "SmarterBot",
    "type": "user"
  }
}
```

### Update Custom Attributes (vía MCP)

En lugar de llamar directamente a Chatwoot API para actualizar `custom_attributes`, se usa **MCP service** como intermediario:

**Node: HTTP Request to MCP**
```yaml
Method: POST
URL: https://mcp.smarterbot.cl/tools/chatwoot.update_conversation
Headers:
  - X-SMOS-Identity: smarterbotcl@gmail.com
  - X-SMOS-HMAC: sha256={{computed_hmac}}
Body:
  {
    "conversation_id": 12345,
    "custom_attributes": {
      "ocr_text": "Factura N° 123...",
      "ocr_method": "vision_api",
      "intent": "consulta_producto",
      "classification_confidence": 0.95
    }
  }
```

**Ventajas de usar MCP:**
- **Rate limiting** centralizado (evita 429 de Chatwoot)
- **Audit trail** automático (Redpanda)
- **Secrets management** unificado (Vault)
- **Multi-tenant isolation** (validación por RUT/inbox_id)

---

## 🔐 Seguridad y Autenticación

### HMAC Verification (Chatwoot → n8n)

**Chatwoot envia:**
```http
X-Chatwoot-Signature: sha256=abc123...
```

**n8n verifica:**
```javascript
const crypto = require('crypto');
const secret = process.env.CHATWOOT_HMAC_SECRET; // From Vault
const payload = JSON.stringify($json);
const signature = $node["Webhook"].headers["x-chatwoot-signature"];

const expected = 'sha256=' + crypto.createHmac('sha256', secret)
  .update(payload)
  .digest('hex');

if (signature !== expected) {
  throw new Error('[RAG-AUDIT:SMARTERBOTCL] Invalid HMAC');
}
```

### API Token (n8n → Chatwoot)

**Header:**
```http
api_access_token: <CHATWOOT_API_TOKEN from Vault>
```

**Permisos requeridos:**
- `conversations:read`
- `conversations:write`
- `messages:read`
- `messages:write`
- `contacts:read`
- `contacts:write`

**Storage:** `vault kv get secret/n8n/chatwoot`
```json
{
  "api_token": "xyz789abc...",
  "hmac_secret": "secret123...",
  "base_url": "https://chatwoot.smarterbot.cl",
  "account_id": "1"
}
```

### Identity Enforcement

**Todas las requests llevan:**
```http
X-SMOS-Identity: smarterbotcl@gmail.com
```

**Logs incluyen:**
```
[RAG-AUDIT:SMARTERBOTCL] Webhook received from Chatwoot: conversation_id=12345
```

---

## 📊 Monitoreo y Debugging

### n8n Execution Logs

**Dashboard:** `https://n8n.smarterbot.cl/executions`

**Filtros útiles:**
- Workflow: `Chatwoot → n8n OCR + Classify`
- Status: `error` (solo fallos)
- Trigger: `webhook`

**Métricas clave:**
- **Execution time:** debe ser <15s para OCR completo
- **Error rate:** debe ser <5%
- **Throughput:** 10 req/min máximo (rate limit de Google Vision)

### Redpanda Audit Logs

**Topic:** `smarteros.audit.ocr`

**Mensaje ejemplo:**
```json
{
  "timestamp": "2025-11-17T15:30:00Z",
  "event": "ocr_completed",
  "conversation_id": 12345,
  "ocr_method": "vision_api",
  "intent": "consulta_producto",
  "latency_ms": 4200,
  "cost_usd": 0.0015,
  "identity": "smarterbotcl@gmail.com",
  "audit_tag": "[RAG-AUDIT:SMARTERBOTCL]"
}
```

**Consultar logs:**
```bash
rpk topic consume smarteros.audit.ocr --brokers=redpanda.smarterbot.cl:9092
```

### Chatwoot Webhook Logs

**Dashboard:** `chatwoot.smarterbot.cl/app/accounts/1/settings/integrations/webhooks`

**Verifica:**
- **Status:** 200 OK (éxito) vs 4xx/5xx (error)
- **Response time:** <1s para webhook (n8n responde inmediatamente, procesa async)
- **Retry count:** Chatwoot reintenta 3 veces con backoff exponencial

---

## 🛠️ Deployment Checklist

### 1. Configurar Chatwoot Webhook

- [ ] Login a `chatwoot.smarterbot.cl`
- [ ] Settings → Inboxes → [Tu Inbox] → Webhook
- [ ] URL: `https://n8n.smarterbot.cl/webhook/chatwoot-events`
- [ ] Events: `message_created`, `conversation_created`, `conversation_updated`
- [ ] Guardar y probar con "Test Webhook"

### 2. Cargar secrets a Vault

```bash
# Chatwoot credentials
vault kv put secret/n8n/chatwoot \
  api_token="xyz789..." \
  hmac_secret="secret123..." \
  base_url="https://chatwoot.smarterbot.cl" \
  account_id="1"

# Google Service Account (JSON key)
vault kv put secret/n8n/google-sa @service-account.json

# MCP credentials
vault kv put secret/n8n/mcp \
  base_url="https://mcp.smarterbot.cl" \
  hmac_secret="mcp_secret456..."
```

### 3. Configurar credenciales en n8n

- [ ] Login a `n8n.smarterbot.cl`
- [ ] Settings → Credentials → Add Credential
- [ ] **Chatwoot (Header Auth):**
  - Name: `chatwoot`
  - Header Name: `api_access_token`
  - Header Value: (from Vault `secret/n8n/chatwoot/api_token`)
- [ ] **Google Service Account:**
  - Type: `Google Service Account`
  - JSON: (paste from Vault `secret/n8n/google-sa`)
  - Scopes: `https://www.googleapis.com/auth/cloud-platform`
- [ ] **MCP (Header Auth):**
  - Name: `mcp`
  - Headers: `X-SMOS-Identity: smarterbotcl@gmail.com` + `X-SMOS-HMAC: ...`

### 4. Importar workflows

```bash
# Descargar workflows del repo
curl -o ocr-workflow.json https://raw.githubusercontent.com/SmarterCL/SmarterOS/main/docs/n8n-workflow-ocr-classify.md

# Importar en n8n UI
# Workflows → Import from File → ocr-workflow.json
```

### 5. Configurar Dashboard

- [ ] Login a `app.smarterbot.cl`
- [ ] Settings → Webhook URL: `https://n8n.smarterbot.cl/webhook/dashboard-sync`
- [ ] Guardar cambios
- [ ] Probar creando un contacto nuevo (debe sincronizar a Chatwoot)

### 6. Test end-to-end

- [ ] Enviar mensaje con imagen a Chatwoot inbox
- [ ] Verificar execution en `n8n.smarterbot.cl/executions`
- [ ] Verificar respuesta en Chatwoot conversation
- [ ] Verificar custom_attributes actualizados
- [ ] Verificar evento en Redpanda topic `smarteros.audit.ocr`

---

## 🚨 Troubleshooting

### Error: "Invalid HMAC signature"

**Causa:** Secret de HMAC no coincide entre Chatwoot y n8n.

**Fix:**
1. Regenerar secret: `openssl rand -hex 32`
2. Actualizar en Chatwoot webhook settings
3. Actualizar en Vault: `vault kv put secret/n8n/chatwoot hmac_secret="<new_secret>"`
4. Reiniciar workflow en n8n

### Error: "Rate limit exceeded" (Google Vision)

**Causa:** Superaste 1800 requests/minuto (limit de Vision API).

**Fix:**
1. Agregar rate limiting en n8n (node "Wait" con delay de 100ms entre requests)
2. Implementar queue en Redpanda para procesar batch en off-peak
3. Cambiar a Document AI (20 req/s limit, más alto)

### Error: "Chatwoot API 401 Unauthorized"

**Causa:** Token de Chatwoot expiró o es inválido.

**Fix:**
1. Regenerar token en `chatwoot.smarterbot.cl/app/accounts/1/settings/integrations`
2. Actualizar en Vault: `vault kv put secret/n8n/chatwoot api_token="<new_token>"`
3. Re-configurar credential en n8n UI

### n8n workflow no se ejecuta

**Causa:** Webhook path incorrecto o n8n no responde.

**Debug:**
1. Verificar URL: `curl -X POST https://n8n.smarterbot.cl/webhook/chatwoot-events` (debe retornar 200 o 400, no 404)
2. Verificar logs en Azure Container Apps: `azd logs --follow`
3. Verificar DNS: `nslookup n8n.smarterbot.cl` (debe resolver a Azure ACA FQDN)

---

## 📚 Referencias

- **Chatwoot API Docs:** https://www.chatwoot.com/developers/api
- **n8n Webhook Node:** https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-base.webhook/
- **Google Vision API:** https://cloud.google.com/vision/docs/ocr
- **Document AI:** https://cloud.google.com/document-ai/docs/process-documents-ocr
- **Gemini API:** https://ai.google.dev/docs/gemini_api_overview
- **HashiCorp Vault:** https://developer.hashicorp.com/vault/docs
- **Azure Container Apps:** https://learn.microsoft.com/en-us/azure/container-apps/

---

**Última actualización:** 2025-11-17  
**Responsable:** smarterbotcl@gmail.com  
**Audit Tag:** [RAG-AUDIT:SMARTERBOTCL]
