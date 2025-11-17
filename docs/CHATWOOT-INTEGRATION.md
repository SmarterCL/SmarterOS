# 💬 Chatwoot Integration - SmarterOS

**Servicio**: Mensajería omnicanal unificada  
**URL**: `https://chatwoot.smarterbot.cl`  
**Versión**: v2.10.1  
**Estado**: ✅ Operativo y integrado con Dashboard

---

## 🎯 Propósito

Chatwoot es el **centro de mensajería unificado** de SmarterOS, consolidando:

- **WhatsApp Business API** (canal principal)
- **Email** (soporte por correo)
- **Web Chat** (widget en sitios web)
- **API Channel** (integraciones custom)

Todas las conversaciones de todos los canales fluyen a través de Chatwoot, permitiendo:
- Respuestas unificadas
- Historial centralizado
- Automatización con N8N
- Métricas de soporte
- Asignación de agentes

---

## 🏗️ Arquitectura

```
Customer
  ↓
WhatsApp / Email / Web
  ↓
Chatwoot Inbox (chatwoot.smarterbot.cl)
  ↓
API REST
  ↓
Dashboard SmarterOS (app.smarterbot.cl)
  ├─ Tab "Mensajes"
  │  ├─ Lista de conversaciones
  │  ├─ Vista de mensajes
  │  └─ Envío de respuestas
  └─ Integración con N8N
     ├─ Webhooks (new message, conversation status)
     ├─ Automatizaciones
     └─ AI Agents (respuestas automáticas)
```

---

## 📦 Componentes

### 1. Backend (Docker Compose)

**Archivo**: `dkcompose/docker-compose.yml`

```yaml
services:
  chatwoot:
    image: ghcr.io/chatwoot/chatwoot:v2.10.1
    container_name: smarter-chatwoot
    environment:
      FRONTEND_URL: https://chatwoot.smarterbot.cl
      SECRET_KEY_BASE: ${CHATWOOT_SECRET_KEY_BASE}
      REDIS_URL: redis://smarter-redis:6379
      DATABASE_URL: postgres://chatwoot:chatwoot@smarter-postgres:5432/chatwoot
    labels:
      - "traefik.http.routers.chatwoot.rule=Host(`chatwoot.smarterbot.cl`)"

  chatwoot-worker:
    image: ghcr.io/chatwoot/chatwoot:v2.10.1
    command: ["bundle", "exec", "sidekiq"]

  chatwoot-scheduler:
    image: ghcr.io/chatwoot/chatwoot:v2.10.1
    command: ["bundle", "exec", "whenever", "--update-crontab"]
```

### 2. Frontend Integration (Next.js)

**Componentes**:
- `components/chatwoot-widget.tsx` - Widget principal con inboxes y conversaciones
- `lib/chatwoot-client.ts` - Cliente TypeScript para Chatwoot API
- `app/api/chatwoot/[...path]/route.ts` - Proxy autenticado a Chatwoot API

**Tab en Dashboard**:
```typescript
const tabItems = [
  { value: "overview", label: "Overview", icon: BarChart3 },
  { value: "messages", label: "Mensajes", icon: MessageSquare }, // ← NUEVO
  { value: "contacts", label: "Contactos", icon: Users },
  // ...
]
```

### 3. API Routes

**GET `/api/chatwoot/inboxes`**
- Lista todos los inboxes (WhatsApp, Email, Web)

**GET `/api/chatwoot/conversations?status=open&inboxId=1`**
- Lista conversaciones con filtros

**GET `/api/chatwoot/conversations/:id/messages`**
- Obtiene mensajes de una conversación

**POST `/api/chatwoot/conversations/:id/messages`**
- Envía mensaje a una conversación

**POST `/api/chatwoot/conversations/:id/toggle_status`**
- Cambia estado (open ↔ resolved)

**GET `/api/chatwoot/contacts/search?q=juan`**
- Busca contactos por nombre/email

---

## 🔐 Configuración

### Variables de Entorno

**VPS (Docker Compose)**:
```bash
CHATWOOT_SECRET_KEY_BASE=xxxx  # Rails secret (generado con `rails secret`)
```

**App Dashboard (Vercel)**:
```bash
CHATWOOT_BASE_URL=https://chatwoot.smarterbot.cl
CHATWOOT_ACCOUNT_ID=1
CHATWOOT_ACCESS_TOKEN=xxxx  # Generado en Chatwoot UI
```

### Generar Access Token

1. Login en `https://chatwoot.smarterbot.cl`
2. Settings → Profile Settings → Access Token
3. Copiar token y guardar en Vercel env vars

---

## 🔌 Integraciones

### WhatsApp Business API

**Setup**:
1. Crear inbox en Chatwoot: "Inboxes → Add Inbox → WhatsApp"
2. Configurar webhook URL: `https://chatwoot.smarterbot.cl/webhooks/whatsapp`
3. Conectar con número verificado de WhatsApp Business

**Flujo**:
```
Cliente envía mensaje WhatsApp
  → Meta Webhook
  → Chatwoot Inbox
  → Dashboard "Mensajes" tab
  → Agente responde
  → N8N automation (opcional)
  → WhatsApp API
  → Cliente recibe respuesta
```

### Shopify

**Objetivo**: Clientes pueden hacer pedidos por WhatsApp

**Setup**:
1. Instalar Shopify Messenger App
2. Conectar con mismo número WhatsApp
3. Configurar webhooks:
   - `order.created` → N8N → Chatwoot (notificar cliente)
   - `fulfillment.updated` → N8N → Chatwoot (actualizar estado)

### N8N Automations

**Workflows activos**:

1. **New Message Trigger**
   - Webhook: Chatwoot → N8N
   - Analiza mensaje con GPT-4
   - Responde automáticamente si es FAQ
   - Crea ticket en Odoo si es complejo

2. **Order Confirmation**
   - Shopify order.created → N8N
   - Busca contacto en Chatwoot
   - Envía confirmación por WhatsApp

3. **AI Agent (Auto-reply)**
   - Detecta preguntas frecuentes
   - Responde automáticamente
   - Marca conversación como resuelta

---

## 📊 Métricas

### KPIs en Dashboard

- **Conversaciones activas**: Open conversations count
- **Tiempo primera respuesta**: Average first response time
- **Tiempo resolución**: Average resolution time
- **Satisfacción cliente**: CSAT score (si se activa)

### Metabase Dashboard

**Query SQL** (desde PostgreSQL de Chatwoot):
```sql
SELECT
  DATE(created_at) as date,
  COUNT(*) as conversations,
  AVG(EXTRACT(EPOCH FROM (first_reply_created_at - created_at))) as avg_first_response_sec
FROM conversations
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

---

## 🚀 Deployment

### VPS (Primera vez)

```bash
ssh root@smarterbot.cl
cd /opt/SmarterOS/dkcompose

# Generar secret
export CHATWOOT_SECRET_KEY_BASE=$(openssl rand -hex 64)

# Deploy
docker-compose up -d chatwoot chatwoot-worker chatwoot-scheduler

# Verificar logs
docker logs -f smarter-chatwoot

# Crear superadmin
docker exec -it smarter-chatwoot bundle exec rails console
> User.create!(name: 'Admin', email: 'admin@smarterbot.cl', password: 'CHANGE_ME', role: :administrator)
```

### Dashboard Update

```bash
# En local
cd /Users/mac/dev/2025/app.smarterbot.cl

# Generar access token en Chatwoot UI
# Agregar a Vercel env vars:
vercel env add CHATWOOT_ACCESS_TOKEN

# Deploy
git add .
git commit -m "feat: Chatwoot integration"
git push  # Auto-deploy via Vercel
```

---

## 🧪 Testing

### Test API Connection

```bash
# Desde terminal
curl -X GET https://app.smarterbot.cl/api/chatwoot/inboxes \
  -H "Cookie: __session=YOUR_CLERK_SESSION"

# Respuesta esperada:
{
  "success": true,
  "data": [
    {
      "id": 1,
      "name": "WhatsApp Inbox",
      "channel_type": "Channel::WhatsApp"
    }
  ]
}
```

### Test Widget

1. Login en `https://app.smarterbot.cl/dashboard`
2. Click en tab "Mensajes"
3. Deberías ver inboxes cargados
4. Click en conversación → ver mensajes
5. Enviar mensaje de prueba

---

## 🔧 Troubleshooting

### Error: "CHATWOOT_ACCESS_TOKEN environment variable is required"

**Solución**:
```bash
vercel env add CHATWOOT_ACCESS_TOKEN
# Pegar token generado en Chatwoot UI
vercel --prod  # Redeploy
```

### Error: "Unauthorized" en /api/chatwoot

**Causa**: No estás autenticado con Clerk

**Solución**: Login en `app.smarterbot.cl` primero

### Inboxes vacíos

**Causa**: No hay inboxes configurados en Chatwoot

**Solución**:
1. Login en `chatwoot.smarterbot.cl`
2. Settings → Inboxes → Add Inbox
3. Configurar WhatsApp/Email/Web

---

## 📚 Recursos

- [Chatwoot Official Docs](https://www.chatwoot.com/docs)
- [Chatwoot API Reference](https://www.chatwoot.com/developers/api)
- [WhatsApp Business API Setup](https://www.chatwoot.com/docs/product/channels/whatsapp/whatsapp-cloud)
- [N8N Chatwoot Integration](https://docs.n8n.io/integrations/builtin/app-nodes/n8n-nodes-base.chatwoot/)

---

## 🎯 Roadmap

### Phase 1 ✅ (Complete)
- [x] Chatwoot deployment en VPS
- [x] Widget integration en Dashboard
- [x] API proxy autenticado
- [x] Tab "Mensajes" funcional

### Phase 2 🔜 (Next)
- [ ] WhatsApp Business API connection
- [ ] Shopify webhook → Chatwoot
- [ ] N8N automation workflows
- [ ] AI auto-reply (GPT-4)

### Phase 3 🔮 (Future)
- [ ] Sentiment analysis
- [ ] CSAT surveys
- [ ] Agent performance dashboard
- [ ] Multi-tenant inbox isolation

---

**Última actualización**: 17 de noviembre de 2025  
**Mantenedor**: SmarterCL Team
