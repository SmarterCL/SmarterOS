#!/usr/bin/env bash
# 🧪 Test Vault Isolation - SmarterOS
#
# Verifica que cada agente solo pueda acceder a los MCPs permitidos
#
# Uso:
#   export VAULT_TOKEN_GEMINI=hvs.xxx
#   export VAULT_TOKEN_COPILOT=hvs.yyy
#   export VAULT_TOKEN_CODEX=hvs.zzz
#   ./test-vault-isolation.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
ORANGE='\033[0;33m'
NC='\033[0m'

# Check if tokens are set
if [ -z "${VAULT_TOKEN_GEMINI:-}" ] || [ -z "${VAULT_TOKEN_COPILOT:-}" ] || [ -z "${VAULT_TOKEN_CODEX:-}" ]; then
    echo -e "${RED}✗ Error: Missing agent tokens${NC}"
    echo ""
    echo "Run first:"
    echo "  cd ~/dev/2025/scripts"
    echo "  ./apply-vault-policies.sh --tokens"
    echo ""
    echo "Then export the tokens:"
    echo "  export VAULT_TOKEN_GEMINI=hvs.xxx"
    echo "  export VAULT_TOKEN_COPILOT=hvs.yyy"
    echo "  export VAULT_TOKEN_CODEX=hvs.zzz"
    exit 1
fi

# Test result counters
GEMINI_ALLOWED=0
GEMINI_DENIED=0
COPILOT_ALLOWED=0
COPILOT_DENIED=0
CODEX_ALLOWED=0
CODEX_DENIED=0

# Test helper: should allow
test_should_allow() {
    local agent=$1
    local token=$2
    local path=$3
    local desc=$4
    
    if VAULT_TOKEN="$token" vault kv get "$path" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $desc: Access granted (expected)"
        return 0
    elif VAULT_TOKEN="$token" vault kv get "$path" 2>&1 | grep -q "No value found"; then
        echo -e "${GREEN}✓${NC} $desc: Path exists, no data yet (expected)"
        return 0
    else
        echo -e "${RED}✗${NC} $desc: Access denied (UNEXPECTED)"
        return 1
    fi
}

# Test helper: should deny
test_should_deny() {
    local agent=$1
    local token=$2
    local path=$3
    local desc=$4
    
    if VAULT_TOKEN="$token" vault kv get "$path" 2>&1 | grep -q "permission denied"; then
        echo -e "${GREEN}✓${NC} $desc: Correctly denied (expected)"
        return 0
    else
        echo -e "${RED}✗${NC} $desc: Access granted (SECURITY ISSUE)"
        return 1
    fi
}

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🧪 Vault Isolation Smoke Test - SmarterOS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ━━━ Test Gemini ━━━
echo -e "${BLUE}🔵 Testing Gemini (AI + Business, NO Infrastructure)${NC}"
echo ""

echo -e "${BLUE}  Should ALLOW:${NC}"
test_should_allow "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/openai" "  OpenAI API" && ((GEMINI_ALLOWED++))
test_should_allow "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/anthropic" "  Anthropic API" && ((GEMINI_ALLOWED++))
test_should_allow "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/shopify" "  Shopify (business data)" && ((GEMINI_ALLOWED++))
test_should_allow "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/metabase" "  Metabase (analytics)" && ((GEMINI_ALLOWED++))
test_should_allow "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/slack" "  Slack (notifications)" && ((GEMINI_ALLOWED++))
test_should_allow "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/stripe" "  Stripe (payments)" && ((GEMINI_ALLOWED++))

echo ""
echo -e "${BLUE}  Should DENY:${NC}"
test_should_deny "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/ssh/deploy" "  SSH keys (infra)" && ((GEMINI_DENIED++))
test_should_deny "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/cloudflare" "  Cloudflare (DNS)" && ((GEMINI_DENIED++))
test_should_deny "gemini" "$VAULT_TOKEN_GEMINI" "smarteros/mcp/aws" "  AWS (cloud)" && ((GEMINI_DENIED++))

echo ""

# ━━━ Test Copilot ━━━
echo -e "${PURPLE}🟣 Testing Copilot (Code Structure ONLY, NO Business/Infra)${NC}"
echo ""

echo -e "${PURPLE}  Should ALLOW:${NC}"
test_should_allow "copilot" "$VAULT_TOKEN_COPILOT" "smarteros/mcp/github" "  GitHub (repos)" && ((COPILOT_ALLOWED++))
test_should_allow "copilot" "$VAULT_TOKEN_COPILOT" "smarteros/mcp/supabase" "  Supabase (DB schema)" && ((COPILOT_ALLOWED++))

echo ""
echo -e "${PURPLE}  Should DENY:${NC}"
test_should_deny "copilot" "$VAULT_TOKEN_COPILOT" "smarteros/mcp/shopify" "  Shopify (business)" && ((COPILOT_DENIED++))
test_should_deny "copilot" "$VAULT_TOKEN_COPILOT" "smarteros/mcp/metabase" "  Metabase (analytics)" && ((COPILOT_DENIED++))
test_should_deny "copilot" "$VAULT_TOKEN_COPILOT" "smarteros/mcp/openai" "  OpenAI (AI API)" && ((COPILOT_DENIED++))
test_should_deny "copilot" "$VAULT_TOKEN_COPILOT" "smarteros/ssh/deploy" "  SSH keys (infra)" && ((COPILOT_DENIED++))
test_should_deny "copilot" "$VAULT_TOKEN_COPILOT" "smarteros/mcp/cloudflare" "  Cloudflare (DNS)" && ((COPILOT_DENIED++))

echo ""

# ━━━ Test Codex ━━━
echo -e "${ORANGE}🟠 Testing Codex (Infrastructure/Ops ONLY, NO AI/Analytics)${NC}"
echo ""

echo -e "${ORANGE}  Should ALLOW:${NC}"
test_should_allow "codex" "$VAULT_TOKEN_CODEX" "smarteros/ssh/deploy" "  SSH keys (deployment)" && ((CODEX_ALLOWED++))
test_should_allow "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/docker" "  Docker (containers)" && ((CODEX_ALLOWED++))
test_should_allow "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/cloudflare" "  Cloudflare (DNS/CDN)" && ((CODEX_ALLOWED++))
test_should_allow "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/aws" "  AWS (cloud infra)" && ((CODEX_ALLOWED++))

echo ""
echo -e "${ORANGE}  Should DENY:${NC}"
test_should_deny "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/openai" "  OpenAI (AI API)" && ((CODEX_DENIED++))
test_should_deny "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/anthropic" "  Anthropic (AI API)" && ((CODEX_DENIED++))
test_should_deny "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/shopify" "  Shopify (business)" && ((CODEX_DENIED++))
test_should_deny "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/metabase" "  Metabase (analytics)" && ((CODEX_DENIED++))
test_should_deny "codex" "$VAULT_TOKEN_CODEX" "smarteros/mcp/stripe" "  Stripe (payments)" && ((CODEX_DENIED++))

echo ""

# ━━━ Summary ━━━
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Test Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

TOTAL_TESTS=$((GEMINI_ALLOWED + GEMINI_DENIED + COPILOT_ALLOWED + COPILOT_DENIED + CODEX_ALLOWED + CODEX_DENIED))
EXPECTED_GEMINI=9
EXPECTED_COPILOT=7
EXPECTED_CODEX=9
EXPECTED_TOTAL=$((EXPECTED_GEMINI + EXPECTED_COPILOT + EXPECTED_CODEX))

echo -e "${BLUE}🔵 Gemini:${NC}    ✓ $GEMINI_ALLOWED allowed (expected 6)  ✓ $GEMINI_DENIED denied (expected 3)"
echo -e "${PURPLE}🟣 Copilot:${NC}   ✓ $COPILOT_ALLOWED allowed (expected 2)  ✓ $COPILOT_DENIED denied (expected 5)"
echo -e "${ORANGE}🟠 Codex:${NC}     ✓ $CODEX_ALLOWED allowed (expected 4)  ✓ $CODEX_DENIED denied (expected 5)"
echo ""

if [ $TOTAL_TESTS -eq $EXPECTED_TOTAL ]; then
    echo -e "${GREEN}✨ All isolation tests passed! ($TOTAL_TESTS/$EXPECTED_TOTAL)${NC}"
    echo ""
    echo -e "${GREEN}Vault policies are correctly enforcing least-privilege access.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed ($TOTAL_TESTS/$EXPECTED_TOTAL)${NC}"
    echo ""
    echo "Review policies with:"
    echo "  vault policy list"
    echo "  vault policy read agent-gemini-mcp-access"
    exit 1
fi
