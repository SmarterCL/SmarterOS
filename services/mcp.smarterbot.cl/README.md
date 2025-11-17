# mcp.smarterbot.cl (MCP Server mínimo)

Servicio HTTP mínimo que expone herramientas ("MCP tools") como endpoints REST y maneja webhooks desde Chatwoot.

- `POST /tools/google.contacts.lookup` → Busca contacto en Google Contacts (People API)
- `POST /webhook/chatwoot` → Recibe eventos de Chatwoot (message_created, conversation_created, etc.)

> Nota: Este servidor no implementa el wire del protocolo MCP-WebSocket; provee endpoints HTTP pensados para las automations de Chatwoot y para orquestación. Puedes envolverlo en un MCP formal más adelante si lo requieres.

## Requisitos

- Node.js 20+
- Credenciales OAuth de Google Workspace con acceso a People API.

Variables de entorno (`.env`):

```
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REFRESH_TOKEN=
GOOGLE_REDIRECT_URI=
PORT=3100
LOG_LEVEL=info
```

## Uso local

```bash
cd services/mcp.smarterbot.cl
cp .env.example .env
pnpm i --ignore-scripts
pnpm dev
# GET http://localhost:3100/health → { ok: true }
```

Probar el tool:

```bash
curl -s -X POST http://localhost:3100/tools/google.contacts.lookup \
  -H 'Content-Type: application/json' \
  -d '{ "email": "juan@example.com" }' | jq
```

## Despliegue en VPS (Dokploy)

Puedes ejecutar este servicio como contenedor básico (ejemplo):

```bash
# Dockerfile mínimo (opcional)
# FROM node:20-alpine
# WORKDIR /app
# COPY . .
# RUN npm i --omit=dev
# EXPOSE 3100
# CMD ["node","server.js"]

# docker compose (ejemplo rápido)
# services:
#   mcp:
#     image: node:20-alpine
#     working_dir: /app
#     command: node server.js
#     ports: ["3100:3100"]
#     volumes:
#       - ./:/app
#     environment:
#       - PORT=3100
#       - GOOGLE_CLIENT_ID=${GOOGLE_CLIENT_ID}
#       - GOOGLE_CLIENT_SECRET=${GOOGLE_CLIENT_SECRET}
#       - GOOGLE_REFRESH_TOKEN=${GOOGLE_REFRESH_TOKEN}
```

Luego, apúntalo en Traefik como `mcp.smarterbot.cl` si deseas exponerlo.

## Chatwoot Automations

Importa `docs/chatwoot-smarteros-automation.json` y ajusta URLs si es necesario.

- Enriquecimiento Google Contacts al crear conversación (WhatsApp)
- Clasificación de intención (placeholder)
- Respuesta de bienvenida (tenant)
