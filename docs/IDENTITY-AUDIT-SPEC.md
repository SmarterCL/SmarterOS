# Identity Audit Spec — SmarterOS

Etiqueta oficial: [RAG-AUDIT:SMARTERBOTCL]
Identidad corporativa única permitida: smarterbotcl@gmail.com

Cualquier otra identidad (correo) está prohibida en código, repos, scripts, MCP, envs o documentación. El sistema de RAG debe reportarlo como incidente.

---

## Scope cubierto
- Google: People API, Contacts API, OAuth 2.0, Refresh Tokens, Workspace
- MCP: Tools y Webhooks (mcp.smarterbot.cl)
- n8n: Workflows y credenciales
- Chatwoot: Automations y Webhooks
- CI/CD: GitHub Actions y artefactos
- Infra: `dkcompose`, Vault, Redpanda, Postgres, Redis

## Reglas
- Permitido: solo `smarterbotcl@gmail.com` como identidad Google en credenciales y referencias.
- Prohibido: cualquier otra dirección de correo en:
  - nombres de variables, valores de variables, comentarios, docs, commits, issues, PRs, logs.
- Credenciales Google (obligatorias para MCP):
  - `GOOGLE_CLIENT_ID`
  - `GOOGLE_CLIENT_SECRET`
  - `GOOGLE_REFRESH_TOKEN`
  - `GOOGLE_REDIRECT_URI=https://mcp.smarterbot.cl/oauth2/callback`
- Almacenamiento de secretos:
  - Nunca en Git/repo/commits; solo `.env` en VPS (temporal) y luego Vault.
- Etiquetado RAG en runtime y en artefactos:
  - Var de entorno `RAG_IDENTITY=smarterbotcl@gmail.com` en servicios que interactúan con Google.
  - Incluir `[RAG-AUDIT:SMARTERBOTCL]` en logs relevantes, headers de eventos, o metadatos cuando aplique.

## Auditoría diaria (RAG)
- Código (paths):
  - `services/**`, `smarteros-specs/**`, `dkcompose/**`, `docs/**`, `app.smarterbot.cl/**`, `chatwoot.smarterbot.cl/**`
- Artefactos sensibles: `.env*`, YAML/JSON de configs, CI workflows
- Logs/Tráfico:
  - MCP inbound/outbound
  - Webhooks de Chatwoot
  - Triggers de n8n
  - Auditoría de Vault
  - Headers en bus de datos Redpanda (`X-SMOS-Tenant`, etiquetas RAG)
- Tópicos Redpanda:
  - `smarteros.audit.identity` → eventos de hallazgos

### Criterios de hallazgo
- Si aparece cualquier correo distinto de `smarterbotcl@gmail.com` →
  - Reportar: `RAG ALERT: Unauthorized identity reference detected.`
  - Severidad: Alta
  - Acción: bloqueo de deploy (si en CI) o ticket automático

## Implementación recomendada

### 1) Scans locales/CI
Comandos de verificación rápidos:

```bash
# Buscar correos no permitidos (excluye el oficial)
grep -RInE "[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+" \
  --exclude-dir=node_modules \
  --exclude-dir=.git \
  --exclude=pnpm-lock.yaml \
  . | grep -v "smarterbotcl@gmail.com" || true

# Buscar tokens/secretos en texto (heurístico)
grep -RInE "(SECRET|TOKEN|API_KEY|CLIENT_ID|CLIENT_SECRET)\s*=\s*['\"]?[^'\"\s]+" \
  --exclude-dir=node_modules --exclude-dir=.git . || true
```

CI (GitHub Actions) — regla mínima:
- Step que ejecute los grep anteriores; si hay resultados → `exit 1` + comentario con `RAG ALERT`.

### 2) MCP — enforce de identidad
- `services/mcp.smarterbot.cl/.env` debe incluir `RAG_IDENTITY=smarterbotcl@gmail.com`.
- Logs deben incluir `[RAG-AUDIT:SMARTERBOTCL]` y `RAG_IDENTITY`.
- Validar que cualquier integración Google use ese contexto.

### 3) Vault
- Tras el deploy inicial con `.env` en VPS, migrar a Vault:
  - Path sugerido: `secret/data/mcp/google`
  - Policies: solo lectura por el servicio MCP.
  - Rotación: Refresh Token y Client Secret según política trimestral.

## Políticas de repositorio
- Nunca commitear `.env` ni credenciales.
- Prohibidos correos personales o de pruebas.
- PR checklist:
  - [ ] ¿Aparece algún correo ≠ `smarterbotcl@gmail.com`?
  - [ ] ¿Se filtró algún secreto?
  - [ ] ¿Se actualizó la doc si cambió el flujo de identidad?

## Respuesta ante incidentes
- Alerta: `RAG ALERT: Unauthorized identity reference detected.`
- Acciones:
  1) Bloquear merge/deploy (si aplica).
  2) Abrir issue con contexto del hallazgo y paths.
  3) Remediar (reemplazo, borrado, reemisión de tokens si hubo exposición).
  4) Post-mortem corto y actualización de reglas si corresponde.

## Checklist de despliegue (MCP)
- VPS `.env`:
  - `GOOGLE_CLIENT_ID`/`SECRET`/`REFRESH_TOKEN` → emitidos para `smarterbotcl@gmail.com`.
  - `GOOGLE_REDIRECT_URI=https://mcp.smarterbot.cl/oauth2/callback`.
  - `RAG_IDENTITY=smarterbotcl@gmail.com`.
- Despliegue:
  - `scripts/smos deploy mcp` → verificar `/health`.
- Post-deploy:
  - Migrar secretos a Vault y retirar `.env` plano cuanto antes.
  - Activar tarea RAG diaria (CI o cron en VPS) y publicar resultados en `smarteros.audit.identity`.
