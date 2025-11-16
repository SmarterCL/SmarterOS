# call.smarterbot.cl — Microsoft Call Center AI

Este directorio alojará el código de `microsoft/call-center-ai` para el subdominio `call.smarterbot.cl`.

Instrucciones rápidas:

- Clonar el repo oficial dentro de este directorio:

  ```bash
  git clone https://github.com/microsoft/call-center-ai .
  ```

- Variables de entorno (SSO con app.smarterbot.cl vía Supabase):

  ```bash
  export NEXT_PUBLIC_SUPABASE_URL="${SUPABASE_URL}"
  export NEXT_PUBLIC_SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY}"
  export SUPABASE_SERVICE_ROLE_KEY="${SUPABASE_SERVICE_ROLE_KEY}"
  ```

- Construcción/ejecución:

  Este proyecto puede requerir dependencias de Azure/Realtime/Speech. El contenedor se construye con `dkcompose/docker-compose.mkt-call.yml` y expone el puerto `3020` para Traefik.
