#!/usr/bin/env bash
# 🔐 Apply Vault Policies - MCP & Agents
#
# Aplica todas las políticas de Vault para MCP providers y agentes tri-agent
#
# Uso:
#   ./apply-vault-policies.sh              # Aplicar todas
#   ./apply-vault-policies.sh --mcp-only   # Solo MCPs
#   ./apply-vault-policies.sh --agents     # Solo agentes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICIES_DIR="$(cd "$SCRIPT_DIR/../smarteros-specs/vault/policies" && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Check Vault connection
check_vault() {
    if ! vault status &> /dev/null; then
        log_error "Cannot connect to Vault. Set VAULT_ADDR and VAULT_TOKEN"
        exit 1
    fi
    
    log_success "Vault connection OK"
}

# Apply a single policy
apply_policy() {
    local policy_name=$1
    local policy_file=$2
    
    if [ ! -f "$policy_file" ]; then
        log_error "Policy file not found: $policy_file"
        return 1
    fi
    
    log_info "Applying policy: $policy_name"
    
    if vault policy write "$policy_name" "$policy_file"; then
        log_success "  → $policy_name applied"
        return 0
    else
        log_error "  → Failed to apply $policy_name"
        return 1
    fi
}

# Apply MCP provider policies
apply_mcp_policies() {
    echo -e "\n${BLUE}━━━ MCP Provider Policies ━━━${NC}\n"
    
    local policies=(
        "mcp-hostinger-read:mcp-hostinger-read.hcl"
        "mcp-github-read:mcp-github-read.hcl"
        "mcp-supabase-read:mcp-supabase-read.hcl"
        "mcp-shopify-gemini-read:mcp-shopify-gemini-read.hcl"
        "mcp-slack-write:mcp-slack-write.hcl"
    )
    
    local success=0
    local failed=0
    
    for policy_entry in "${policies[@]}"; do
        IFS=':' read -r name file <<< "$policy_entry"
        if apply_policy "$name" "$POLICIES_DIR/$file"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    log_info "MCP Policies: $success applied, $failed failed"
}

# Apply agent policies
apply_agent_policies() {
    echo -e "\n${BLUE}━━━ Agent Policies ━━━${NC}\n"
    
    local policies=(
        "agent-gemini-mcp-access:agent-gemini-mcp-access.hcl"
        "agent-copilot-mcp-access:agent-copilot-mcp-access.hcl"
        "agent-codex-mcp-access:agent-codex-mcp-access.hcl"
    )
    
    local success=0
    local failed=0
    
    for policy_entry in "${policies[@]}"; do
        IFS=':' read -r name file <<< "$policy_entry"
        if apply_policy "$name" "$POLICIES_DIR/$file"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    log_info "Agent Policies: $success applied, $failed failed"
}

# Apply admin policies
apply_admin_policies() {
    echo -e "\n${BLUE}━━━ Admin Policies ━━━${NC}\n"
    
    local policies=(
        "mcp-admin-full:mcp-admin-full.hcl"
        "ci-readonly:ci-readonly.hcl"
    )
    
    local success=0
    local failed=0
    
    for policy_entry in "${policies[@]}"; do
        IFS=':' read -r name file <<< "$policy_entry"
        if apply_policy "$name" "$POLICIES_DIR/$file"; then
            ((success++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    log_info "Admin Policies: $success applied, $failed failed"
}

# List all policies
list_policies() {
    echo -e "\n${BLUE}━━━ Current Policies ━━━${NC}\n"
    vault policy list
}

# Create roles for agents
create_agent_roles() {
    echo -e "\n${BLUE}━━━ Creating Agent Roles ━━━${NC}\n"
    
    # Role for Gemini
    log_info "Creating role: agent-gemini"
    vault write auth/token/roles/agent-gemini \
        allowed_policies="agent-gemini-mcp-access" \
        orphan=true \
        renewable=true \
        token_period=24h
    log_success "  → agent-gemini role created"
    
    # Role for Copilot
    log_info "Creating role: agent-copilot"
    vault write auth/token/roles/agent-copilot \
        allowed_policies="agent-copilot-mcp-access" \
        orphan=true \
        renewable=true \
        token_period=24h
    log_success "  → agent-copilot role created"
    
    # Role for Codex
    log_info "Creating role: agent-codex"
    vault write auth/token/roles/agent-codex \
        allowed_policies="agent-codex-mcp-access" \
        orphan=true \
        renewable=true \
        token_period=24h
    log_success "  → agent-codex role created"
    
    # Role for CI
    log_info "Creating role: ci"
    vault write auth/token/roles/ci \
        allowed_policies="ci-readonly" \
        orphan=false \
        renewable=true \
        token_period=1h
    log_success "  → ci role created"
}

# Generate tokens for agents (for testing)
generate_agent_tokens() {
    echo -e "\n${BLUE}━━━ Generating Test Tokens ━━━${NC}\n"
    
    log_warning "Generating test tokens (use carefully!)"
    echo ""
    
    # Gemini token
    log_info "Token for Gemini:"
    GEMINI_TOKEN=$(vault token create -policy=agent-gemini-mcp-access -period=24h -format=json | jq -r '.auth.client_token')
    echo "  export VAULT_TOKEN_GEMINI=$GEMINI_TOKEN"
    echo ""
    
    # Copilot token
    log_info "Token for Copilot:"
    COPILOT_TOKEN=$(vault token create -policy=agent-copilot-mcp-access -period=24h -format=json | jq -r '.auth.client_token')
    echo "  export VAULT_TOKEN_COPILOT=$COPILOT_TOKEN"
    echo ""
    
    # Codex token
    log_info "Token for Codex:"
    CODEX_TOKEN=$(vault token create -policy=agent-codex-mcp-access -period=24h -format=json | jq -r '.auth.client_token')
    echo "  export VAULT_TOKEN_CODEX=$CODEX_TOKEN"
    echo ""
    
    log_warning "Store these tokens in Vault or secure location!"
}

# Main
main() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  🔐 Vault Policy Manager - SmarterOS  ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"
    
    check_vault
    
    local mode="all"
    
    if [ $# -gt 0 ]; then
        case $1 in
            --mcp-only)
                mode="mcp"
                ;;
            --agents)
                mode="agents"
                ;;
            --admin)
                mode="admin"
                ;;
            --list)
                list_policies
                exit 0
                ;;
            --roles)
                create_agent_roles
                exit 0
                ;;
            --tokens)
                generate_agent_tokens
                exit 0
                ;;
            *)
                echo "Usage: $0 [--mcp-only|--agents|--admin|--list|--roles|--tokens]"
                exit 1
                ;;
        esac
    fi
    
    case $mode in
        mcp)
            apply_mcp_policies
            ;;
        agents)
            apply_agent_policies
            ;;
        admin)
            apply_admin_policies
            ;;
        all)
            apply_mcp_policies
            apply_agent_policies
            apply_admin_policies
            create_agent_roles
            ;;
    esac
    
    list_policies
    
    echo -e "\n${GREEN}✨ Done! All policies applied${NC}\n"
    
    log_info "Next steps:"
    echo "  1. Generate tokens: $0 --tokens"
    echo "  2. Test access: vault token lookup <TOKEN>"
    echo "  3. Bootstrap MCPs: ./bootstrap-mcp-vault.sh"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
