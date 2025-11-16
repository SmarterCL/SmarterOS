#!/usr/bin/env bash
# 🔐 Install Vault CLI - macOS
#
# Instala HashiCorp Vault CLI en tu Mac
#
# Uso:
#   ./install-vault-cli.sh

set -euo pipefail

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

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🔐 Install Vault CLI - macOS         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

# Check if vault is already installed
if command -v vault &> /dev/null; then
    CURRENT_VERSION=$(vault version | head -n1 | awk '{print $2}')
    log_success "Vault already installed: $CURRENT_VERSION"
    echo ""
    vault version
    exit 0
fi

# Check if Homebrew is available
if command -v brew &> /dev/null; then
    log_info "Installing Vault via Homebrew..."
    echo ""
    
    # Add HashiCorp tap
    log_info "Adding HashiCorp tap..."
    brew tap hashicorp/tap
    
    # Install Vault
    log_info "Installing Vault..."
    brew install hashicorp/tap/vault
    
    echo ""
    log_success "Vault installed successfully!"
    echo ""
    
    vault version
    
else
    log_warning "Homebrew not found, installing via direct binary..."
    echo ""
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ]; then
        VAULT_URL="https://releases.hashicorp.com/vault/1.18.1/vault_1.18.1_darwin_arm64.zip"
    else
        VAULT_URL="https://releases.hashicorp.com/vault/1.18.1/vault_1.18.1_darwin_amd64.zip"
    fi
    
    log_info "Downloading Vault for $ARCH..."
    curl -O "$VAULT_URL"
    
    log_info "Extracting..."
    unzip -q vault_1.18.1_darwin_*.zip
    
    log_info "Installing to /usr/local/bin..."
    sudo mv vault /usr/local/bin/
    
    log_info "Cleaning up..."
    rm -f vault_1.18.1_darwin_*.zip
    
    echo ""
    log_success "Vault installed successfully!"
    echo ""
    
    vault version
fi

# Configure shell environment
echo ""
log_info "Configuring environment..."
echo ""

SHELL_RC=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC="$HOME/.bashrc"
fi

if [ -n "$SHELL_RC" ]; then
    if ! grep -q "VAULT_ADDR" "$SHELL_RC"; then
        echo "" >> "$SHELL_RC"
        echo "# Vault configuration" >> "$SHELL_RC"
        echo "export VAULT_ADDR=\"https://vault.smarterbot.cl:8200\"" >> "$SHELL_RC"
        echo "# export VAULT_TOKEN=\"<your_token>\"  # Set this manually" >> "$SHELL_RC"
        
        log_success "Added VAULT_ADDR to $SHELL_RC"
        echo ""
        log_warning "Please run: source $SHELL_RC"
    else
        log_info "VAULT_ADDR already configured in $SHELL_RC"
    fi
fi

# Enable autocomplete (optional)
log_info "Setting up autocomplete..."
vault -autocomplete-install 2>/dev/null || true

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✨ Vault CLI ready!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

log_info "Next steps:"
echo ""
echo "1. Set Vault address (if not in shell config):"
echo "   export VAULT_ADDR=\"https://vault.smarterbot.cl:8200\""
echo ""
echo "2. Set your Vault token:"
echo "   export VAULT_TOKEN=\"<your_root_or_admin_token>\""
echo ""
echo "3. Test connection:"
echo "   vault status"
echo ""
echo "4. Apply policies:"
echo "   cd ~/dev/2025/scripts"
echo "   ./apply-vault-policies.sh"
echo ""
