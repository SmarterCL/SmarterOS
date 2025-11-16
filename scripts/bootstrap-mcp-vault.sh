#!/usr/bin/env bash
set -euo pipefail

# Bootstrap de secretos MCP en Vault (multi-proveedor)
# Requiere: VAULT_ADDR y VAULT_TOKEN exportados
# Uso básico:
#   export VAULT_ADDR=https://vault.smarterbot.cl
#   export VAULT_TOKEN=<root_or_admin_token>
#   ./bootstrap-mcp-vault.sh              # crea placeholders de todos
#   MCP_PROVIDERS="hostinger,openai" ./bootstrap-mcp-vault.sh
#   OPENAI_API_KEY=sk-... ./bootstrap-mcp-vault.sh   # inyecta cuando existan variables

: "${VAULT_ADDR:?VAULT_ADDR requerido}"
: "${VAULT_TOKEN:?VAULT_TOKEN requerido}"

BASE_PATH=${BASE_PATH:-smarteros/mcp}
IFS=',' read -r -a PROVIDERS <<< "${MCP_PROVIDERS:-hostinger,github,context7,cloudflare,shopify,supabase,docker,openai,anthropic,google,aws,slack,linear,notion,metabase,mailgun,twilio,whatsapp,odoo,n8n,shopify,pos,stripe}"

ts() { date -Iseconds; }

put_secret() {
  local path="$1"; shift
  if [ $# -eq 0 ]; then
    vault kv put "$path" placeholder=true created_at="$(ts)"
  else
    vault kv put "$path" "$@"
  fi
}

bootstrap_provider() {
  local p="$1"
  local path="$BASE_PATH/$p"
  local args=()
  case "$p" in
    hostinger)
      # Hostinger API MCP (https://github.com/hostinger/api-mcp-server)
      [ -n "${MCP_HOSTINGER_API_TOKEN:-}" ] && args+=("api_token=${MCP_HOSTINGER_API_TOKEN}")
      args+=("endpoint=${MCP_HOSTINGER_ENDPOINT:-https://api.hostinger.com}")
      ;;
    github)
      [ -n "${GITHUB_TOKEN_MCP:-}" ] && args+=("token=${GITHUB_TOKEN_MCP}")
      ;;
    context7)
      [ -n "${CONTEXT7_API_KEY:-}" ] && args+=("api_key=${CONTEXT7_API_KEY}")
      args+=("endpoint=${CONTEXT7_ENDPOINT:-https://api.context7.com}")
      ;;
    cloudflare)
      [ -n "${CLOUDFLARE_API_TOKEN:-}" ] && args+=("api_token=${CLOUDFLARE_API_TOKEN}")
      [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ] && args+=("account_id=${CLOUDFLARE_ACCOUNT_ID}")
      [ -n "${CLOUDFLARE_ZONE_ID:-}" ] && args+=("zone_id=${CLOUDFLARE_ZONE_ID}")
      ;;
    shopify)
      [ -n "${SHOPIFY_ADMIN_API_ACCESS_TOKEN:-}" ] && args+=("admin_api_access_token=${SHOPIFY_ADMIN_API_ACCESS_TOKEN}")
      [ -n "${SHOPIFY_STORE_DOMAIN:-}" ] && args+=("store_domain=${SHOPIFY_STORE_DOMAIN}")
      args+=("api_version=${SHOPIFY_API_VERSION:-2024-10}")
      ;;
    supabase)
      [ -n "${SUPABASE_URL:-}" ] && args+=("url=${SUPABASE_URL}")
      [ -n "${SUPABASE_ANON_KEY:-}" ] && args+=("anon_key=${SUPABASE_ANON_KEY}")
      [ -n "${SUPABASE_SERVICE_ROLE:-}" ] && args+=("service_role=${SUPABASE_SERVICE_ROLE}")
      ;;
    docker)
      [ -n "${DOCKER_REGISTRY:-}" ] && args+=("registry=${DOCKER_REGISTRY}")
      [ -n "${DOCKER_USERNAME:-}" ] && args+=("username=${DOCKER_USERNAME}")
      [ -n "${DOCKER_PASSWORD:-}" ] && args+=("password=${DOCKER_PASSWORD}")
      ;;
    openai)
      [ -n "${OPENAI_API_KEY:-}" ] && args+=("api_key=${OPENAI_API_KEY}")
      [ -n "${OPENAI_BASE_URL:-}" ] && args+=("endpoint=${OPENAI_BASE_URL}")
      ;;
    anthropic)
      [ -n "${ANTHROPIC_API_KEY:-}" ] && args+=("api_key=${ANTHROPIC_API_KEY}")
      ;;
    google)
      [ -n "${GOOGLE_PROJECT_ID:-}" ] && args+=("project_id=${GOOGLE_PROJECT_ID}")
      [ -n "${GOOGLE_CREDENTIALS_JSON:-}" ] && args+=("credentials_json=${GOOGLE_CREDENTIALS_JSON}")
      ;;
    aws)
      [ -n "${AWS_ACCESS_KEY_ID:-}" ] && args+=("access_key_id=${AWS_ACCESS_KEY_ID}")
      [ -n "${AWS_SECRET_ACCESS_KEY:-}" ] && args+=("secret_access_key=${AWS_SECRET_ACCESS_KEY}")
      args+=("region=${AWS_REGION:-us-east-1}")
      ;;
    slack)
      [ -n "${SLACK_BOT_TOKEN:-}" ] && args+=("bot_token=${SLACK_BOT_TOKEN}")
      [ -n "${SLACK_SIGNING_SECRET:-}" ] && args+=("signing_secret=${SLACK_SIGNING_SECRET}")
      ;;
    linear)
      [ -n "${LINEAR_API_KEY:-}" ] && args+=("api_key=${LINEAR_API_KEY}")
      ;;
    notion)
      [ -n "${NOTION_API_KEY:-}" ] && args+=("api_key=${NOTION_API_KEY}")
      ;;
    metabase)
      [ -n "${METABASE_URL:-}" ] && args+=("url=${METABASE_URL}")
      [ -n "${METABASE_USERNAME:-}" ] && args+=("username=${METABASE_USERNAME}")
      [ -n "${METABASE_PASSWORD:-}" ] && args+=("password=${METABASE_PASSWORD}")
      ;;
    mailgun)
      [ -n "${MAILGUN_API_KEY:-}" ] && args+=("api_key=${MAILGUN_API_KEY}")
      [ -n "${MAILGUN_DOMAIN:-}" ] && args+=("domain=${MAILGUN_DOMAIN}")
      args+=("endpoint=${MAILGUN_ENDPOINT:-https://api.mailgun.net}")
      ;;
    twilio)
      [ -n "${TWILIO_ACCOUNT_SID:-}" ] && args+=("account_sid=${TWILIO_ACCOUNT_SID}")
      [ -n "${TWILIO_AUTH_TOKEN:-}" ] && args+=("auth_token=${TWILIO_AUTH_TOKEN}")
      [ -n "${TWILIO_FROM_NUMBER:-}" ] && args+=("from_number=${TWILIO_FROM_NUMBER}")
      ;;
    whatsapp)
      [ -n "${WHATSAPP_TOKEN:-}" ] && args+=("token=${WHATSAPP_TOKEN}")
      [ -n "${WHATSAPP_PHONE_ID:-}" ] && args+=("phone_id=${WHATSAPP_PHONE_ID}")
      [ -n "${WHATSAPP_BUSINESS_ID:-}" ] && args+=("business_id=${WHATSAPP_BUSINESS_ID}")
      ;;
    odoo)
      [ -n "${ODOO_URL:-}" ] && args+=("url=${ODOO_URL}")
      [ -n "${ODOO_DB:-}" ] && args+=("db=${ODOO_DB}")
      [ -n "${ODOO_USERNAME:-}" ] && args+=("username=${ODOO_USERNAME}")
      [ -n "${ODOO_PASSWORD:-}" ] && args+=("password=${ODOO_PASSWORD}")
      ;;
    n8n)
      [ -n "${N8N_URL:-}" ] && args+=("url=${N8N_URL}")
      [ -n "${N8N_API_KEY:-}" ] && args+=("api_key=${N8N_API_KEY}")
      ;;
    stripe)
      [ -n "${STRIPE_SECRET_KEY:-}" ] && args+=("secret_key=${STRIPE_SECRET_KEY}")
      ;;
    pos)
      # Placeholder para POS (ej. Square/Stripe Terminal)
      [ -n "${POS_PROVIDER:-}" ] && args+=("provider=${POS_PROVIDER}")
      [ -n "${POS_API_KEY:-}" ] && args+=("api_key=${POS_API_KEY}")
      ;;
    *)
      ;;
  esac
  echo "→ ${p}: escribiendo en ${path}"
  put_secret "$path" "${args[@]}"
}

echo "📚 MCP providers a bootstrapear: ${PROVIDERS[*]}"
for p in "${PROVIDERS[@]}"; do
  bootstrap_provider "$p"
done

echo "✅ MCP bootstrap completado en base: ${BASE_PATH}"
