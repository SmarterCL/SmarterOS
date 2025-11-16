# fulldaygo.smarterbot.cl — Full Day Go Marketplace

Este directorio alojará el código del marketplace Full Day Go para el subdominio `fulldaygo.smarterbot.cl`.

## Instrucciones rápidas

### Clonar el repositorio
```bash
git clone https://github.com/SmarterCL/fulldaygo.smarterbot.cl .
```

### Variables de entorno (SSO con app.smarterbot.cl vía Supabase)
```bash
export NEXT_PUBLIC_SUPABASE_URL="${SUPABASE_URL}"
export NEXT_PUBLIC_SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
export SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}"
```

### Desarrollo local (opcional)
```bash
pnpm install || npm ci
pnpm dev || npm run dev
```

## Deployment

El deployment en el VPS se realiza vía Docker Compose usando `dkcompose/docker-compose.front-services.yml` con Traefik.

## Características

- **Login compartido**: Usa las mismas credenciales de Supabase que app.smarterbot.cl
- **SSO**: Cross-domain session habilitado
- **Puerto**: 3030
- **Proxy**: Traefik con SSL automático (Let's Encrypt)
