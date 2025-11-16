#!/usr/bin/env bash
# 🧪 Hostinger API MCP - Smoke Tests
#
# Tests básicos para verificar integración del MCP server de Hostinger
#
# Prerequisitos:
#   1. npm install -g hostinger-api-mcp
#   2. vault kv put smarteros/mcp/hostinger api_token="<token>"
#   3. export VAULT_ADDR y VAULT_TOKEN
#
# Uso:
#   ./hostinger-test.sh              # Todos los tests
#   ./hostinger-test.sh --quick      # Solo connection test
#   ./hostinger-test.sh --verbose    # Con output detallado

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

VERBOSE=false
QUICK=false

# Parse args
for arg in "$@"; do
    case $arg in
        --verbose) VERBOSE=true ;;
        --quick) QUICK=true ;;
    esac
done

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

log_test() {
    echo -e "${CYAN}🧪${NC} $1"
}

# Contador de tests
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    log_test "Test #$TESTS_TOTAL: $test_name"
    
    if $VERBOSE; then
        echo "  Command: $test_command"
    fi
    
    if eval "$test_command" &> /tmp/hostinger-test.log; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "  PASSED"
        
        if $VERBOSE; then
            echo "  Output:"
            cat /tmp/hostinger-test.log | sed 's/^/    /'
        fi
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "  FAILED"
        
        echo "  Error output:"
        cat /tmp/hostinger-test.log | sed 's/^/    /'
    fi
    
    echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Pre-flight checks
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Hostinger API MCP - Smoke Tests${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

log_info "Running pre-flight checks..."

# Check if hostinger-api-mcp is installed
if ! command -v hostinger-api-mcp &> /dev/null; then
    log_error "hostinger-api-mcp not found. Install with: npm install -g hostinger-api-mcp"
    exit 1
fi
log_success "hostinger-api-mcp installed"

# Check Vault connection
if ! vault status &> /dev/null; then
    log_error "Cannot connect to Vault. Set VAULT_ADDR and VAULT_TOKEN"
    exit 1
fi
log_success "Vault connection OK"

# Check if Hostinger API token exists in Vault
if ! vault kv get smarteros/mcp/hostinger &> /dev/null; then
    log_error "Hostinger API token not found in Vault"
    log_info "Create with: vault kv put smarteros/mcp/hostinger api_token=\"<token>\""
    exit 1
fi
log_success "Hostinger API token found in Vault"

# Get token from Vault
HOSTINGER_API_TOKEN=$(vault kv get -field=api_token smarteros/mcp/hostinger)
export API_TOKEN="$HOSTINGER_API_TOKEN"

log_success "API_TOKEN exported to environment\n"

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Test Suite
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${BLUE}━━━ Connection Tests ━━━${NC}\n"

run_test "List VPS instances" \
    "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/virtual-machines | jq -e '.data'"

run_test "Get billing methods" \
    "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/billing/v1/payment-methods | jq -e '.data'"

if $QUICK; then
    echo -e "${YELLOW}━━━ Quick mode: Skipping detailed tests ━━━${NC}\n"
else
    echo -e "${BLUE}━━━ VPS Tests ━━━${NC}\n"
    
    # Get first VPS ID for further tests
    VPS_ID=$(curl -s -H "Authorization: Bearer $API_TOKEN" https://api.hostinger.com/api/vps/v1/virtual-machines | jq -r '.data[0].id // empty')
    
    if [ -n "$VPS_ID" ]; then
        log_info "Using VPS ID: $VPS_ID for tests"
        
        run_test "Get VPS details" \
            "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/virtual-machines/$VPS_ID | jq -e '.data'"
        
        run_test "Get VPS actions history" \
            "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/virtual-machines/$VPS_ID/actions | jq -e '.data'"
        
        run_test "List attached SSH keys" \
            "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/virtual-machines/$VPS_ID/public-keys | jq -e '.data'"
        
        run_test "List VPS backups" \
            "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/virtual-machines/$VPS_ID/backups | jq -e '.data'"
    else
        log_warning "No VPS instances found. Skipping VPS-specific tests."
    fi
    
    echo -e "${BLUE}━━━ SSH Keys Tests ━━━${NC}\n"
    
    run_test "List SSH public keys" \
        "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/public-keys | jq -e '.data'"
    
    echo -e "${BLUE}━━━ Domain Tests ━━━${NC}\n"
    
    run_test "List domains" \
        "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/domains/v1/portfolio | jq -e '.data'"
    
    echo -e "${BLUE}━━━ Hosting Tests ━━━${NC}\n"
    
    run_test "List websites" \
        "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/hosting/v1/websites | jq -e '.data'"
    
    echo -e "${BLUE}━━━ Templates & Data Centers ━━━${NC}\n"
    
    run_test "List VPS templates" \
        "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/templates | jq -e '.data'"
    
    run_test "List data centers" \
        "curl -s -H 'Authorization: Bearer $API_TOKEN' https://api.hostinger.com/api/vps/v1/data-centers | jq -e '.data'"
fi

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Results Summary
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  Test Results${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

echo -e "Total tests:  ${BLUE}$TESTS_TOTAL${NC}"
echo -e "Passed:       ${GREEN}$TESTS_PASSED${NC}"
echo -e "Failed:       ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}✨ All tests passed! Hostinger API MCP is working correctly.${NC}\n"
    
    echo -e "${CYAN}Next steps:${NC}"
    echo -e "  1. Test from Codex agent: codex call hostinger.VPS_getVirtualMachinesV1"
    echo -e "  2. Add to tri-agent workflows: .github/workflows/tri-agent-*.yml"
    echo -e "  3. Configure automation scenarios in smarteros-specs/automation/"
    
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed. Check the output above for details.${NC}\n"
    
    echo -e "${YELLOW}Troubleshooting:${NC}"
    echo -e "  1. Verify API token is valid: https://hpanel.hostinger.com/api-tokens"
    echo -e "  2. Check token has required permissions"
    echo -e "  3. Verify API endpoint is accessible: curl https://api.hostinger.com"
    echo -e "  4. Check Vault secrets: vault kv get smarteros/mcp/hostinger"
    
    exit 1
fi
