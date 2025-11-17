# Deploy de chatwoot.smarterbot.cl en Vercel

Guía rápida para desplegar el frontend de Chatwoot (Next.js 15) en Vercel.

## Requisitos
- Proyecto `chatwoot.smarterbot.cl` conectado a Vercel
- Chatwoot backend operativo (Docker, ver `dkcompose/README-CHATWOOT.md`)

## Variables de entorno (Vercel)
Configura en Project Settings → Environment Variables:

- `CHATWOOT_API_URL` → `https://api.chatwoot.smarterbot.cl`
- `CHATWOOT_ACCOUNT_ID` → `1` (o el ID del account)
- `CHATWOOT_ACCESS_TOKEN` → token de acceso (Profile → Access Token en Chatwoot)
- `NEXT_PUBLIC_APP_URL` → `https://chatwoot.smarterbot.cl`
- (Opcional) `NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY`, `CLERK_SECRET_KEY`

Recomendado: setear para `Preview` y `Production`.

## Deploy (CLI)

```bash
# Desde la carpeta del proyecto
cd chatwoot.smarterbot.cl

# Vincula el proyecto
vercel link

# Carga variables (si no usaste el panel UI)
vercel env add CHATWOOT_API_URL
vercel env add CHATWOOT_ACCOUNT_ID
vercel env add CHATWOOT_ACCESS_TOKEN
vercel env add NEXT_PUBLIC_APP_URL

# Despliegue a producción
vercel --prod
```

## Verificación
- Abrir `https://chatwoot.smarterbot.cl`
- Probar acceso a endpoints internos del proxy: `GET /api/chatwoot/accounts/:id/inboxes`
- Validar WebSocket (si aplica) y latencia de mensajes

## Troubleshooting
- 401/403 → revisar token y `CHATWOOT_ACCOUNT_ID`
- 404 al proxy → revisar ruta de `app/api/chatwoot/[...path]/route.ts`
- CORS → no aplica con proxy del mismo dominio; si usas otros orígenes, habilitar CORS en el backend o usar el proxy siempre
