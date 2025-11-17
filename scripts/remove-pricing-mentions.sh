#!/bin/bash
#
# remove-pricing-mentions.sh
# Limpia menciones de precios del repositorio (compliance: leyes de seguridad y búsqueda)
# Prioridad: BAJA
# Frecuencia: 1 vez por semana (domingos a las 3:00 AM)
#

set -euo pipefail

REPO_ROOT="/Users/mac/dev/2025"
LOG_FILE="${REPO_ROOT}/.logs/pricing-cleanup-$(date +%Y%m%d-%H%M%S).log"
COMMIT_MESSAGE="chore: Remove pricing mentions (weekly compliance cleanup)"

# Crear directorio de logs si no existe
mkdir -p "${REPO_ROOT}/.logs"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== INICIO: Limpieza de precios del repositorio ==="

# =============================================================================
# PASO 1: Buscar menciones de precios
# =============================================================================

log "PASO 1: Buscando menciones de precios..."

PRICING_PATTERN='\$[0-9,.]+(K|CLP|USD)?|[0-9,.]+ (CLP|USD)|precio|price|gratis|free.*trial|cost|pago|payment'

# Buscar en archivos relevantes (excluir node_modules, .git, etc.)
MATCHES=$(grep -rni -E "$PRICING_PATTERN" \
    --include="*.{md,yml,yaml,ts,tsx,js,jsx,json}" \
    --exclude-dir="node_modules" \
    --exclude-dir=".git" \
    --exclude-dir="dist" \
    --exclude-dir="build" \
    --exclude-dir=".next" \
    "${REPO_ROOT}" || true)

if [ -z "$MATCHES" ]; then
    log "✅ No se encontraron menciones de precios. Repositorio limpio."
    exit 0
fi

log "⚠️ Se encontraron $(echo "$MATCHES" | wc -l) menciones de precios:"
echo "$MATCHES" >> "$LOG_FILE"

# =============================================================================
# PASO 2: Filtrar false positives (template strings, GitHub Actions, etc.)
# =============================================================================

log "PASO 2: Filtrando false positives..."

# Excluir:
# - Template strings: className=${...}, text-${...}
# - GitHub Actions: ${{ secrets.TOKEN }}
# - Vault errors: ${resp.status}
# - URL parameters: ?${params}
# - fulldaygo.smarterbot.cl (e-commerce product, prices intencionales)

FILTERED_MATCHES=$(echo "$MATCHES" | \
    grep -v 'className=\${' | \
    grep -v 'text-\${' | \
    grep -v '\${{' | \
    grep -v 'fulldaygo.smarterbot.cl' || true)

if [ -z "$FILTERED_MATCHES" ]; then
    log "✅ Todas las menciones son false positives. No hay nada que limpiar."
    exit 0
fi

log "⚠️ $(echo "$FILTERED_MATCHES" | wc -l) menciones verdaderas de precios encontradas."

# =============================================================================
# PASO 3: Limpiar archivos específicos
# =============================================================================

log "PASO 3: Limpiando archivos..."

cd "${REPO_ROOT}/smarteros-specs"

# Archivo 1: smarteros-specs/services/botpress-agent.yml
# Eliminar sección COST ESTIMATION (líneas 838-869)

if [ -f "services/botpress-agent.yml" ]; then
    log "Limpiando services/botpress-agent.yml..."
    
    # Reemplazar cost_per_1k con placeholder
    sed -i.bak 's/cost_per_1k: "\$0.00001"/cost_per_1k: "< threshold"/g' services/botpress-agent.yml
    
    # Eliminar sección completa de COST ESTIMATION
    # (asumiendo que está entre líneas 838-869)
    sed -i.bak '838,869d' services/botpress-agent.yml
    
    # Anonimizar ejemplos con montos (líneas 709, 711)
    sed -i.bak 's/\$150.000 y \$80.000/XXX.XXX y XX.XXX/g' services/botpress-agent.yml
    sed -i.bak 's/genera link de pago/genera link de compra/g' services/botpress-agent.yml
    
    log "✅ services/botpress-agent.yml limpio"
fi

# Archivo 2: smarteros-specs/BACKLOG-Q1-2025-BOTPRESS.md
# Anonimizar montos en ejemplos de test (líneas 222, 225, 259, 279)

if [ -f "BACKLOG-Q1-2025-BOTPRESS.md" ]; then
    log "Limpiando BACKLOG-Q1-2025-BOTPRESS.md..."
    
    # Reemplazar montos específicos con placeholders
    sed -i.bak 's/"amount_due": "\$1,250.00"/"amount_due": "$XXX.XX"/g' BACKLOG-Q1-2025-BOTPRESS.md
    sed -i.bak 's/saldo pendiente de \$1,250.00/saldo pendiente de $XXX.XX/g' BACKLOG-Q1-2025-BOTPRESS.md
    sed -i.bak 's/Factura procesada: \$450.00/Factura procesada: $XXX.XX/g' BACKLOG-Q1-2025-BOTPRESS.md
    sed -i.bak 's/Costo por mensaje | < \$0.005/Costo por mensaje | < threshold/g' BACKLOG-Q1-2025-BOTPRESS.md
    
    log "✅ BACKLOG-Q1-2025-BOTPRESS.md limpio"
fi

# Limpiar backups de sed
find . -name "*.bak" -delete

# =============================================================================
# PASO 4: Commit y push si hay cambios
# =============================================================================

log "PASO 4: Verificando cambios..."

if git diff --quiet; then
    log "✅ No hay cambios para commitear."
    exit 0
fi

log "Cambios detectados. Commiteando..."

git add -A
git commit -m "$COMMIT_MESSAGE"

# Push solo si estamos en main/master
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" == "main" ] || [ "$CURRENT_BRANCH" == "master" ]; then
    log "Pushing a $CURRENT_BRANCH..."
    git push origin "$CURRENT_BRANCH"
    log "✅ Cambios pusheados a GitHub"
else
    log "⚠️ No estamos en main/master. No se hace push automático."
fi

# =============================================================================
# PASO 5: Notificación (opcional)
# =============================================================================

log "PASO 5: Enviando notificación..."

# Enviar email o Slack notification (opcional)
# curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK \
#     -H 'Content-Type: application/json' \
#     -d "{\"text\": \"✅ Limpieza de precios completada: $COMMIT_MESSAGE\"}"

log "=== FIN: Limpieza completada con éxito ==="

# Enviar log por email (opcional)
# mail -s "Pricing Cleanup Report" smarterbotcl@gmail.com < "$LOG_FILE"
