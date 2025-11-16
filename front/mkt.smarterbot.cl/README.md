# mkt.smarterbot.cl — BlogBowl

Este directorio alojará el código de BlogBowl para el subdominio `mkt.smarterbot.cl`.

Instrucciones rápidas:

- Clonar el repo oficial dentro de este directorio:

  ```bash
  git clone https://github.com/BlogBowl/BlogBowl .
  ```

- Variables de entorno (SSO con app.smarterbot.cl vía Supabase):

  ```bash
  export NEXT_PUBLIC_SUPABASE_URL="${SUPABASE_URL}"
  export NEXT_PUBLIC_SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
  ```

- Desarrollo local (opcional):

  ```bash
  pnpm install || npm ci
  pnpm dev || npm run dev
  ```

El deployment en el VPS se realiza vía Docker Compose usando `dkcompose/docker-compose.mkt-call.yml` con Traefik.