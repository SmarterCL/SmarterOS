# ⚠️ DOCUMENTO OBSOLETO - VER CORRECCIÓN

**Fecha**: 16 de noviembre de 2025  
**Status**: ❌ **ANÁLISIS INCORRECTO - NO USAR**

---

## 🚨 AVISO CRÍTICO

Este documento contiene un **análisis fundamentalmente INCORRECTO** sobre Hostinger.

### ❌ Conclusión Errónea Original
> "Hostinger NO es un MCP Provider"

### ✅ Realidad Descubierta
> **Hostinger SÍ ES un MCP Provider oficial** con más de 100 herramientas nativas via `hostinger-api-mcp`

---

## 📖 Leer la Corrección Completa

**Documento correcto**: [`docs/MCP-HOSTINGER-CORRECTION.md`](./MCP-HOSTINGER-CORRECTION.md)

**Spec oficial**: [`smarteros-specs/mcp/hostinger.yml`](../smarteros-specs/mcp/hostinger.yml)

**GitHub oficial**: https://github.com/hostinger/api-mcp-server

---

## 🔍 Por Qué Este Análisis Estaba Mal

1. **No investigué el GitHub de Hostinger** - El MCP server oficial existe desde hace meses
2. **Confundí VPS físico con API de management** - Son dos cosas complementarias
3. **Asumí que SSH era el único método** - La API MCP controla VPS, SSH es para deploy
4. **No validé la existencia del npm package** - `hostinger-api-mcp` está publicado y funcional

---

## 📋 Hallazgos Originales (CONSERVADOS PARA REFERENCIA HISTÓRICA)

**NOTA**: Los siguientes hallazgos asumían incorrectamente que Hostinger no tenía MCP. Se conservan solo como registro del proceso de investigación.

---

## 🎯 Hallazgos

### ✅ Configuración Correcta

**En `smarteros-specs/mcp/index.yml`**:
```yaml
tier_1_core:
  providers:
    - name: "hostinger"
      vault_path: "smarteros/ssh/deploy"  # ✅ Correcto
      required: true
      agents: ["codex"]
      status: "active"
      secrets:
        - private_key
        - public_key
        - host
        - user
```

**En `smarteros-specs/agents/mcp-registry.yml`**:
```yaml
hostinger:
  tier: 1
  category: "core"
  primary_agent: "executor-codex"
  
  auth:
    method: "ssh-key"  # ✅ Correcto (no es API)
    vault_path: "smarteros/ssh/deploy"  # ✅ Correcto
  
  capabilities:
    codex: ["ssh", "rsync", "systemctl_remote"]
  
  connection_test: "ssh smarteros 'echo ok'"
  required: true
```

---

## ❌ Inconsistencias Detectadas

### 1. En `scripts/bootstrap-mcp-vault.sh`

**Problema**: Menciona `MCP_HOSTINGER_API_KEY` que no existe

```bash
# Líneas 35-37 (INCORRECTO)
hostinger)
  [ -n "${MCP_HOSTINGER_API_KEY:-}" ] && args+=("api_key=${MCP_HOSTINGER_API_KEY}")
  args+=("endpoint=${MCP_ENDPOINT:-https://api.hostinger.com}")
```

**Realidad**: Hostinger **no tiene API MCP**, usa **SSH keys** que ya están en `smarteros/ssh/deploy`.

**Corrección recomendada**: Remover el bloque de hostinger del bootstrap script, ya que las SSH keys se crean por separado con `setup-ssh-deploy.sh`.

---

### 2. En `README.md`

**Problema**: Path incorrecto

```markdown
# Línea 450 (INCORRECTO)
- hostinger → `smarteros/mcp/hostinger` (api_key, endpoint)
```

**Corrección recomendada**:
```markdown
- hostinger → `smarteros/ssh/deploy` (private_key, public_key, host, user)
  Nota: Hostinger usa SSH, no API MCP. Las keys se crean con setup-ssh-deploy.sh
```

---

### 3. En `smarteros-specs/index.yml`

**Problema**: Path de config incorrecto

```yaml
# Línea 63 (INCORRECTO o no existe)
hostinger:
  type: "ssh"
  config: "mcp/hostinger.yml"  # Este archivo NO existe
```

**Corrección recomendada**: El archivo `mcp/hostinger.yml` no existe y no debería existir porque Hostinger no es un MCP provider estándar.

---

## 🔧 Naturaleza de Hostinger en SmarterOS

### Hostinger NO es un MCP Provider Tradicional

Hostinger es el **VPS físico** donde corre todo el sistema. No tiene:
- ❌ API REST
- ❌ SDK de cliente
- ❌ Webhooks
- ❌ Tokens de autenticación

Hostinger **SÍ tiene**:
- ✅ Acceso SSH con claves asimétricas
- ✅ Usuario `smarteros` con sudoers
- ✅ Servicios systemd (vault, caddy, docker)
- ✅ Filesystem para rsync

### Posición en la Arquitectura

```
┌─────────────────────────────────────────────┐
│           HOSTINGER VPS (89.116.23.167)     │
│  ┌───────────────────────────────────────┐  │
│  │  Usuario: smarteros                   │  │
│  │  SSH Auth: smarteros/ssh/deploy       │  │
│  │  ┌─────────────────────────────────┐  │  │
│  │  │  Vault OSS :8200                │  │  │
│  │  │  Caddy :80 :443                 │  │  │
│  │  │  Docker (n8n, metabase, etc)    │  │  │
│  │  │  App: /opt/smarteros/apps/main  │  │  │
│  │  └─────────────────────────────────┘  │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
           ▲
           │ SSH + rsync (via Codex)
           │
    ┌──────┴──────┐
    │   Codex     │  (executor-codex)
    │  Agent      │  lee: smarteros/ssh/deploy
    └─────────────┘  ejecuta: rsync, systemctl
```

---

## ✅ Correcciones Recomendadas

### 1. Actualizar `bootstrap-mcp-vault.sh`

**Antes**:
```bash
hostinger)
  [ -n "${MCP_HOSTINGER_API_KEY:-}" ] && args+=("api_key=${MCP_HOSTINGER_API_KEY}")
  args+=("endpoint=${MCP_ENDPOINT:-https://api.hostinger.com}")
```

**Después**:
```bash
# Hostinger usa SSH keys (no MCP API)
# Las keys se crean con setup-ssh-deploy.sh y se guardan en smarteros/ssh/deploy
# No necesita bootstrap aquí, solo verificar que existan:
hostinger)
  echo "⚠ Hostinger uses SSH keys from smarteros/ssh/deploy (not MCP API)"
  echo "  Run setup-ssh-deploy.sh to create SSH keys if needed"
  continue
```

---

### 2. Actualizar `README.md`

**Antes**:
```markdown
- hostinger → `smarteros/mcp/hostinger` (api_key, endpoint)
```

**Después**:
```markdown
- hostinger → `smarteros/ssh/deploy` (private_key, public_key, host, user)
  
  **Nota**: Hostinger NO es un MCP API provider. Es el VPS físico accesible via SSH.
  Las claves se crean con `setup-ssh-deploy.sh` y Codex las usa para rsync/systemctl.
```

---

### 3. Actualizar `smarteros-specs/index.yml`

**Antes**:
```yaml
hostinger:
  type: "ssh"
  config: "mcp/hostinger.yml"  # No existe
```

**Después**:
```yaml
hostinger:
  type: "vps"
  auth_method: "ssh-key"
  vault_path: "smarteros/ssh/deploy"
  config_note: "VPS físico, no MCP API. Ver: smarteros-specs/infra/infrastructure.yml"
```

---

### 4. Crear `smarteros-specs/infra/hostinger.yml` (Opcional)

Si quieres documentar la config de Hostinger, debería estar en `infra/` no en `mcp/`:

```yaml
# smarteros-specs/infra/hostinger.yml
provider: "hostinger"
type: "vps"
plan: "VPS-2"  # 8GB RAM, 4 vCPU

instance:
  ip: "89.116.23.167"
  hostname: "smarteros.smarterbot.cl"
  os: "Ubuntu 24.04 LTS"
  region: "EU"

ssh_access:
  user: "smarteros"
  vault_path: "smarteros/ssh/deploy"
  keys:
    - private_key (ed25519)
    - public_key
  authorized_keys: "/home/smarteros/.ssh/authorized_keys"

services:
  - vault-oss:8200
  - caddy:80,443
  - docker:2375
  - app.smarterbot.cl:/opt/smarteros/apps/main

deployed_by:
  agent: "executor-codex"
  method: "rsync + systemctl"
  scripts:
    - setup-ssh-deploy.sh
    - deploy-app.sh

monitoring:
  uptime: "https://uptime.smarterbot.cl"
  logs: "/var/log/smarteros/"
```

---

## 🎯 Conclusión

**Hostinger NO es un MCP Provider**, es la **infraestructura física** donde corren los servicios.

### Tier 1 Core Providers (revisado):

| Provider | Tipo | Auth | Vault Path | Agente |
|----------|------|------|------------|--------|
| **github** | API MCP | token | `smarteros/mcp/github` | All |
| **vault** | API MCP | token | self | All |
| **docker** | API MCP | socket | `smarteros/mcp/docker` | Codex |
| **hostinger** | VPS SSH | ssh-key | `smarteros/ssh/deploy` | Codex |
| **supabase** | API MCP | api_key | `smarteros/mcp/supabase` | Gemini+Copilot |

### Recomendación Final

1. ✅ Mantener `hostinger` en Tier 1 (es core infrastructure)
2. ✅ Aclarar que usa SSH no API MCP
3. ✅ Remover referencias a `MCP_HOSTINGER_API_KEY`
4. ✅ Corregir paths en README (`smarteros/ssh/deploy` no `smarteros/mcp/hostinger`)
5. ✅ Mover config de `mcp/hostinger.yml` a `infra/hostinger.yml` (si existe)

---

**Estado**: Documentación clara de que Hostinger es VPS+SSH, no MCP API ✅
