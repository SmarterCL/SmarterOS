# 🔄 CORRECCIÓN CRÍTICA: Hostinger MCP Server

**Fecha**: 16 de noviembre de 2025  
**Status**: ✅ **CORRECCIÓN COMPLETA DEL ANÁLISIS ANTERIOR**

---

## 🎯 Hallazgo Crítico

### ❌ Análisis Anterior (INCORRECTO)

El documento `MCP-HOSTINGER-REVIEW.md` concluyó **erróneamente** que:
- ❌ "Hostinger NO es un MCP Provider"
- ❌ "Hostinger es solo el VPS físico con SSH"
- ❌ "No tiene API REST ni SDK de cliente"

### ✅ Realidad (CORRECTO)

**Hostinger SÍ tiene un MCP server oficial**: [`hostinger-api-mcp`](https://github.com/hostinger/api-mcp-server)

```bash
# Instalación oficial
npm install -g hostinger-api-mcp

# Configuración
{
  "mcpServers": {
    "hostinger-api": {
      "command": "hostinger-api-mcp",
      "env": {
        "DEBUG": "false",
        "API_TOKEN": "YOUR_HOSTINGER_API_TOKEN"
      }
    }
  }
}
```

---

## 📦 Capacidades del MCP Server Oficial

### Autenticación

```typescript
// En server.ts línea 5195-5228
const bearerToken = process.env['API_TOKEN'] || process.env['APITOKEN'];
if (!bearerToken) {
  throw new Error('API_TOKEN environment variable not found');
}

const config: AxiosRequestConfig = {
  method: 'get',
  url: fullUrl,
  headers: {
    ...this.headers,
    'Authorization': `Bearer ${bearerToken}`
  }
};
```

**Método de autenticación**: `Bearer Token` (API_TOKEN en env)

---

### Endpoints Disponibles (100+ tools)

#### 1. **Billing & Subscriptions**
- `billing_getPaymentMethodsV1` - Listar métodos de pago
- `billing_setDefaultPaymentMethodV1` - Configurar método default
- `billing_disableAutoRenewalV1` - Deshabilitar auto-renovación
- `billing_enableAutoRenewalV1` - Habilitar auto-renovación

#### 2. **Domains Management**
- `domains_checkDomainAvailabilityV1` - Verificar disponibilidad
- `domains_getDomainListV1` - Listar dominios
- `domains_getDomainDetailsV1` - Detalles de dominio
- `domains_updateDomainNameserversV1` - Actualizar nameservers
- `domains_enablePrivacyProtectionV1` - Activar protección WHOIS
- `domains_disablePrivacyProtectionV1` - Desactivar protección WHOIS
- `domains_getDomainForwardingV1` - Ver forwarding
- `domains_createDomainForwardingV1` - Crear redirect
- `domains_deleteDomainForwardingV1` - Eliminar redirect

#### 3. **Hosting Management**
- `hosting_listWebsitesV1` - Listar websites
- `hosting_createWebsiteV1` - Crear website
- `hosting_importWordpressWebsite` - Importar WordPress

#### 4. **VPS Management** (🔥 MUY IMPORTANTE)
- `VPS_getVirtualMachinesV1` - Listar VPS
- `VPS_getVirtualMachineDetailsV1` - Detalles de VPS
- `VPS_getActionsV1` - Historial de acciones
- `VPS_purchaseNewVirtualMachineV1` - Comprar VPS
- `VPS_setupPurchasedVirtualMachineV1` - Setup inicial

#### 5. **VPS SSH Keys Management** (🔥 CRÍTICO)
- `VPS_getPublicKeysV1` - Listar SSH keys registradas
- `VPS_createPublicKeyV1` - **Crear nueva SSH key**
- `VPS_deletePublicKeyV1` - Eliminar SSH key
- `VPS_attachPublicKeyV1` - **Adjuntar key a VPS**
- `VPS_getAttachedPublicKeysV1` - Ver keys adjuntas a VPS

#### 6. **VPS Operations**
- `VPS_startVirtualMachineV1` - Iniciar VPS
- `VPS_stopVirtualMachineV1` - Detener VPS
- `VPS_rebootVirtualMachineV1` - Reiniciar VPS
- `VPS_recreateVirtualMachineV1` - Recrear VPS
- `VPS_setRootPasswordV1` - Cambiar password root

#### 7. **VPS Firewall**
- `VPS_activateFirewallV1` - Activar firewall
- `VPS_deactivateFirewallV1` - Desactivar firewall
- `VPS_listFirewallsV1` - Listar firewalls

#### 8. **VPS Backups**
- `VPS_getBackupsV1` - Listar backups
- `VPS_createBackupV1` - Crear backup
- `VPS_restoreBackupV1` - Restaurar backup

#### 9. **VPS Docker Management**
- `VPS_getProjectsV1` - Listar proyectos Docker
- `VPS_createProjectV1` - Crear proyecto
- `VPS_updateProjectV1` - Actualizar proyecto

#### 10. **VPS Nameservers**
- `VPS_setNameserversV1` - Configurar DNS resolvers

#### 11. **VPS Templates**
- `VPS_getTemplatesV1` - Listar OS templates
- `VPS_getTemplateDetailsV1` - Detalles de template

#### 12. **VPS Data Centers**
- `VPS_getDataCenterListV1` - Listar data centers

#### 13. **Email Marketing (Reach)**
- `reach_createContactV1` - Crear contacto
- `reach_deleteAContactV1` - Eliminar contacto

---

## 🔧 Configuración Correcta para SmarterOS

### 1. **Vault Path**: `smarteros/mcp/hostinger`

```yaml
# smarteros-specs/mcp/index.yml
tier_1_core:
  providers:
    - name: "hostinger"
      vault_path: "smarteros/mcp/hostinger"  # ✅ CORRECTO (API MCP)
      required: true
      agents: ["codex", "gemini"]  # Codex: VPS ops, Gemini: domains
      status: "active"
      secrets:
        - api_token     # Bearer token de Hostinger API
        - endpoint      # https://api.hostinger.com (opcional, default)
```

### 2. **Agentes que deben acceder**

```yaml
# smarteros-specs/agents/mcp-registry.yml
hostinger:
  tier: 1
  category: "core"
  
  auth:
    method: "bearer-token"  # ✅ CORRECTO (no ssh-key)
    vault_path: "smarteros/mcp/hostinger"
  
  capabilities:
    codex: 
      - "vps_management"           # Listar, start, stop, reboot VPS
      - "ssh_keys_management"      # Crear, adjuntar, listar SSH keys
      - "firewall_management"      # Activar/desactivar firewalls
      - "backup_management"        # Crear, restaurar backups
      - "docker_management"        # Gestionar proyectos Docker en VPS
      - "nameserver_management"    # Configurar DNS resolvers
    
    gemini:
      - "domains_management"       # Verificar disponibilidad, listar dominios
      - "domain_privacy"           # Enable/disable WHOIS privacy
      - "domain_forwarding"        # Crear redirects
      - "billing_info"             # Consultar métodos de pago
    
    copilot:
      - "hosting_management"       # Listar websites, crear websites
      - "wordpress_import"         # Importar WordPress
  
  connection_test: "VPS_getVirtualMachinesV1"
  required: true
```

---

## 🔄 Comparación: SSH vs API MCP

### Confusión Original

El análisis anterior confundió **DOS cosas diferentes**:

#### 1. **SSH Access al VPS** (existente)
```yaml
# smarteros/ssh/deploy
vault_path: "smarteros/ssh/deploy"
secrets:
  - private_key (ed25519)
  - public_key
  - host: 89.116.23.167
  - user: smarteros

uso:
  - rsync de archivos
  - systemctl remote (restart servicios)
  - logs access
  - filesystem operations
```

#### 2. **Hostinger API MCP** (nuevo descubrimiento)
```yaml
# smarteros/mcp/hostinger
vault_path: "smarteros/mcp/hostinger"
secrets:
  - api_token (Bearer token)
  - endpoint (https://api.hostinger.com)

uso:
  - Gestión de VPS (start, stop, reboot)
  - Gestión de SSH keys (crear, adjuntar)
  - Gestión de dominios (check, privacy, forwarding)
  - Gestión de backups (crear, restaurar)
  - Gestión de firewall
  - Gestión de Docker en VPS
  - Gestión de billing
```

### Ambos son válidos y complementarios

```
┌────────────────────────────────────────────────────────┐
│            HOSTINGER INFRASTRUCTURE                    │
├────────────────────────────────────────────────────────┤
│                                                        │
│  ┌──────────────────┐        ┌──────────────────┐     │
│  │  SSH Access      │        │  API MCP Server  │     │
│  │  (Operational)   │        │  (Management)    │     │
│  ├──────────────────┤        ├──────────────────┤     │
│  │ • rsync files    │        │ • Start/Stop VPS │     │
│  │ • systemctl      │        │ • Create SSH keys│     │
│  │ • logs access    │        │ • Manage domains │     │
│  │ • shell commands │        │ • Backups        │     │
│  └──────────────────┘        │ • Firewall       │     │
│         ▲                    └──────────────────┘     │
│         │                            ▲                │
│         │                            │                │
└─────────┼────────────────────────────┼────────────────┘
          │                            │
    ┌─────┴──────┐             ┌───────┴───────┐
    │   Codex    │             │  Codex/Gemini │
    │  (deploy)  │             │  (management) │
    └────────────┘             └───────────────┘
```

---

## ✅ Correcciones Necesarias

### 1. **Actualizar `scripts/bootstrap-mcp-vault.sh`**

**Antes** (INCORRECTO):
```bash
hostinger)
  echo "⚠ Hostinger uses SSH keys from smarteros/ssh/deploy (not MCP API)"
  continue
```

**Después** (CORRECTO):
```bash
hostinger)
  # Hostinger API Token (Bearer) para MCP server oficial
  [ -n "${MCP_HOSTINGER_API_TOKEN:-}" ] && args+=("api_token=${MCP_HOSTINGER_API_TOKEN}")
  args+=("endpoint=${MCP_ENDPOINT:-https://api.hostinger.com}")
  ;;
```

---

### 2. **Actualizar `README.md`**

**Antes** (INCORRECTO):
```markdown
- hostinger → `smarteros/ssh/deploy` (private_key, public_key, host, user)
  Nota: VPS físico, no API MCP
```

**Después** (CORRECTO):
```markdown
- hostinger → `smarteros/mcp/hostinger` (api_token, endpoint)
  
  **MCP Server**: [`hostinger-api-mcp`](https://github.com/hostinger/api-mcp-server)
  **Capabilities**: VPS management, SSH keys, domains, backups, firewall, Docker
  
  **Nota adicional**: El SSH access directo (`smarteros/ssh/deploy`) se mantiene
  separado para operaciones de deploy (rsync, systemctl).
```

---

### 3. **Actualizar `smarteros-specs/mcp/index.yml`**

**Antes** (CONFUSO):
```yaml
- name: "hostinger"
  vault_path: "smarteros/ssh/deploy"  # ❌ Confunde SSH con MCP
  agents: ["codex"]
```

**Después** (CORRECTO):
```yaml
- name: "hostinger"
  vault_path: "smarteros/mcp/hostinger"  # ✅ API MCP
  required: true
  agents: ["codex", "gemini"]  # Ambos usan API
  status: "active"
  mcp_server: "hostinger-api-mcp"
  npm_package: "hostinger-api-mcp"
  secrets:
    - api_token
    - endpoint
```

---

### 4. **Actualizar `smarteros-specs/agents/mcp-registry.yml`**

**Antes** (INCORRECTO):
```yaml
hostinger:
  auth:
    method: "ssh-key"  # ❌ Confunde con SSH access
    vault_path: "smarteros/ssh/deploy"
  capabilities:
    codex: ["ssh", "rsync", "systemctl_remote"]
```

**Después** (CORRECTO):
```yaml
hostinger:
  tier: 1
  category: "core"
  
  auth:
    method: "bearer-token"  # ✅ API Token
    vault_path: "smarteros/mcp/hostinger"
  
  capabilities:
    codex:
      - "vps_lifecycle"        # Start, stop, reboot VPS
      - "ssh_keys_api"         # Crear SSH keys via API (no confundir con uso directo)
      - "firewall_api"         # Gestión de firewall
      - "backup_api"           # Crear/restaurar backups
      - "docker_api"           # Gestión de proyectos Docker
    
    gemini:
      - "domains_api"          # Gestión de dominios
      - "billing_api"          # Info de billing
  
  connection_test: "VPS_getVirtualMachinesV1"
  required: true
  
  notes: |
    IMPORTANTE: Este provider usa el API MCP oficial de Hostinger.
    
    NO confundir con SSH access directo (smarteros/ssh/deploy), 
    que se usa para deploy operations (rsync, systemctl).
    
    Ambos paths son válidos y complementarios:
    - smarteros/mcp/hostinger → API management
    - smarteros/ssh/deploy → Direct SSH operations
```

---

### 5. **Crear `smarteros-specs/mcp/hostinger.yml`**

```yaml
# smarteros-specs/mcp/hostinger.yml
provider: "hostinger"
category: "core"
tier: 1

mcp_server:
  name: "hostinger-api-mcp"
  repository: "https://github.com/hostinger/api-mcp-server"
  npm_package: "hostinger-api-mcp"
  version: "latest"
  
install:
  command: "npm install -g hostinger-api-mcp"
  
config:
  command: "hostinger-api-mcp"
  env:
    DEBUG: "false"
    API_TOKEN: "vault:smarteros/mcp/hostinger:api_token"

auth:
  method: "bearer-token"
  vault_path: "smarteros/mcp/hostinger"
  secrets:
    - name: "api_token"
      type: "string"
      description: "Bearer token de Hostinger API"
      required: true
      get_from: "https://hpanel.hostinger.com/api-tokens"
    
    - name: "endpoint"
      type: "string"
      description: "Base URL del API"
      default: "https://api.hostinger.com"
      required: false

capabilities:
  billing:
    - billing_getPaymentMethodsV1
    - billing_setDefaultPaymentMethodV1
    - billing_disableAutoRenewalV1
    - billing_enableAutoRenewalV1
  
  domains:
    - domains_checkDomainAvailabilityV1
    - domains_getDomainListV1
    - domains_getDomainDetailsV1
    - domains_updateDomainNameserversV1
    - domains_enablePrivacyProtectionV1
    - domains_disablePrivacyProtectionV1
    - domains_getDomainForwardingV1
    - domains_createDomainForwardingV1
    - domains_deleteDomainForwardingV1
  
  hosting:
    - hosting_listWebsitesV1
    - hosting_createWebsiteV1
    - hosting_importWordpressWebsite
  
  vps_lifecycle:
    - VPS_getVirtualMachinesV1
    - VPS_getVirtualMachineDetailsV1
    - VPS_startVirtualMachineV1
    - VPS_stopVirtualMachineV1
    - VPS_rebootVirtualMachineV1
    - VPS_recreateVirtualMachineV1
    - VPS_setRootPasswordV1
    - VPS_purchaseNewVirtualMachineV1
    - VPS_setupPurchasedVirtualMachineV1
    - VPS_getActionsV1
  
  vps_ssh_keys:
    - VPS_getPublicKeysV1
    - VPS_createPublicKeyV1
    - VPS_deletePublicKeyV1
    - VPS_attachPublicKeyV1
    - VPS_getAttachedPublicKeysV1
  
  vps_firewall:
    - VPS_listFirewallsV1
    - VPS_activateFirewallV1
    - VPS_deactivateFirewallV1
  
  vps_backups:
    - VPS_getBackupsV1
    - VPS_createBackupV1
    - VPS_restoreBackupV1
  
  vps_docker:
    - VPS_getProjectsV1
    - VPS_createProjectV1
    - VPS_updateProjectV1
  
  vps_network:
    - VPS_setNameserversV1
  
  vps_templates:
    - VPS_getTemplatesV1
    - VPS_getTemplateDetailsV1
    - VPS_getDataCenterListV1
  
  email_marketing:
    - reach_createContactV1
    - reach_deleteAContactV1

agent_usage:
  executor-codex:
    - "Gestión de VPS (start, stop, reboot)"
    - "Crear y adjuntar SSH keys via API"
    - "Gestión de firewall"
    - "Crear backups"
    - "Gestión de proyectos Docker"
  
  director-gemini:
    - "Verificar disponibilidad de dominios"
    - "Consultar info de billing"
    - "Gestión de dominios (privacy, forwarding)"
  
  writer-copilot:
    - "Listar websites"
    - "Crear websites"
    - "Importar WordPress"

connection_test:
  tool: "VPS_getVirtualMachinesV1"
  expected: "Lista de VPS registrados"

rate_limits:
  default: "No documentado en repo oficial"
  
documentation:
  official: "https://github.com/hostinger/api-mcp-server"
  readme: "https://github.com/hostinger/api-mcp-server/blob/main/README.md"

notes: |
  IMPORTANTE: NO confundir con SSH access directo
  
  Este MCP provider gestiona recursos de Hostinger via API REST.
  
  Para operaciones de deploy directo (rsync, systemctl), usar
  el path separado: smarteros/ssh/deploy (ed25519 keys)
  
  Ambos paths son complementarios:
  - smarteros/mcp/hostinger → API management (este archivo)
  - smarteros/ssh/deploy → Direct SSH operations
```

---

### 6. **Mantener `smarteros-specs/infra/hostinger.yml`**

El archivo de infra creado anteriormente **sigue siendo válido**, solo agregar:

```yaml
# smarteros-specs/infra/hostinger.yml
provider: "hostinger"
type: "vps"
plan: "VPS Business"

# ... contenido existente ...

management:
  api:
    mcp_server: "hostinger-api-mcp"
    vault_path: "smarteros/mcp/hostinger"
    capabilities:
      - "VPS lifecycle (start, stop, reboot)"
      - "SSH keys management via API"
      - "Firewall management"
      - "Backup management"
      - "Docker projects management"
  
  ssh:
    vault_path: "smarteros/ssh/deploy"
    capabilities:
      - "rsync deployments"
      - "systemctl operations"
      - "Log access"
      - "Shell commands"

notes: |
  Hostinger tiene DOS formas de gestión:
  1. API MCP (smarteros/mcp/hostinger) - Management operations
  2. SSH directo (smarteros/ssh/deploy) - Deploy operations
  
  Ambos son válidos y complementarios.
```

---

## 📊 Comparativa Final

| Aspecto | SSH Access | API MCP |
|---------|------------|---------|
| **Vault Path** | `smarteros/ssh/deploy` | `smarteros/mcp/hostinger` |
| **Auth** | SSH Key (ed25519) | Bearer Token (API_TOKEN) |
| **Uso** | Deploy operations | Management operations |
| **Agente principal** | Codex | Codex + Gemini |
| **Operaciones** | rsync, systemctl, logs | Start/Stop VPS, SSH keys API, domains, backups |
| **Prioridad** | Operacional | Estratégica |

---

## 🎯 Conclusión

### ❌ Análisis Anterior (INCORRECTO)
- "Hostinger NO es un MCP Provider"
- "Solo tiene SSH access"
- "No tiene API REST"

### ✅ Realidad (CORRECTO)
- **Hostinger SÍ es un MCP Provider oficial**
- **Tiene un MCP server npm**: `hostinger-api-mcp`
- **Tiene 100+ tools** para gestión completa de VPS, domains, billing, etc
- **El SSH access es complementario**, no excluyente

### 🔄 Acciones Inmediatas

1. ✅ Revertir cambios en `bootstrap-mcp-vault.sh` (restaurar bloque hostinger)
2. ✅ Actualizar `README.md` con vault path correcto (`smarteros/mcp/hostinger`)
3. ✅ Actualizar `smarteros-specs/mcp/index.yml` con auth bearer-token
4. ✅ Crear `smarteros-specs/mcp/hostinger.yml` con config completa
5. ✅ Actualizar `smarteros-specs/agents/mcp-registry.yml` con capabilities API
6. ✅ Mantener `smarteros-specs/infra/hostinger.yml` pero aclarar ambos paths
7. ✅ Obtener API Token desde https://hpanel.hostinger.com/api-tokens
8. ✅ Agregar a bootstrap script: `MCP_HOSTINGER_API_TOKEN`

---

**Status**: ✅ **Análisis corregido completamente**  
**Documento anterior**: `MCP-HOSTINGER-REVIEW.md` → **OBSOLETO**  
**Documento vigente**: `MCP-HOSTINGER-CORRECTION.md` → **ESTE ARCHIVO**
