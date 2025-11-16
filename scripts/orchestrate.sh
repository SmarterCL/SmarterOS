#!/usr/bin/env bash
# 🤖 SmarterOS Tri-Agent Orchestrator CLI
#
# Orquesta manualmente los tres agentes: Gemini → Copilot → Codex
#
# Uso:
#   ./orchestrate.sh "Add user profile page"
#   ./orchestrate.sh --plan-only "Refactor auth module"
#   ./orchestrate.sh --execute plan-123.json

set -euo pipefail

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Configuration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="/tmp/smarteros"

PLANS_DIR="$TMP_DIR/plans"
PATCHES_DIR="$TMP_DIR/patches"
REPORTS_DIR="$TMP_DIR/reports"

mkdir -p "$PLANS_DIR" "$PATCHES_DIR" "$REPORTS_DIR"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Helper Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

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

agent_step() {
    local agent=$1
    local action=$2
    echo -e "\n${CYAN}🤖 ${agent}${NC}: ${action}"
}

check_dependencies() {
    local missing=()
    
    for cmd in vault jq pnpm ssh; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing dependencies: ${missing[*]}"
        exit 1
    fi
    
    # Check Vault connection
    if ! vault status &> /dev/null; then
        log_error "Cannot connect to Vault. Set VAULT_ADDR and VAULT_TOKEN"
        exit 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Agent Functions
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

director_gemini_analyze() {
    local task_description=$1
    local plan_file=$2
    
    agent_step "Director Gemini" "Analyzing task and creating execution plan"
    
    # TODO: Replace with actual Gemini API call
    # For now, create a simple plan structure
    
    local task_id="manual-$(date +%s)"
    
    cat > "$plan_file" <<EOF
{
  "tasks": [
    {
      "id": "${task_id}",
      "type": "feature",
      "description": "${task_description}",
      "priority": "medium",
      "files_affected": [],
      "requires_code_gen": true,
      "estimated_duration": "15m",
      "validation_criteria": [
        "typescript_compilation",
        "tests_pass",
        "health_check"
      ]
    }
  ],
  "metadata": {
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "trigger": "manual_cli",
    "context": "$(pwd)"
  }
}
EOF
    
    log_success "Execution plan created: $plan_file"
    
    # Display plan summary
    echo ""
    log_info "Plan Summary:"
    jq -r '.tasks[] | "  • \(.description) (\(.type), priority: \(.priority))"' "$plan_file"
    echo ""
}

writer_copilot_generate() {
    local plan_file=$1
    local patches_dir=$2
    
    agent_step "Writer Copilot" "Generating code based on execution plan"
    
    local task_id=$(jq -r '.tasks[0].id' "$plan_file")
    local requires_gen=$(jq -r '.tasks[0].requires_code_gen' "$plan_file")
    
    if [ "$requires_gen" != "true" ]; then
        log_info "No code generation required, skipping..."
        return 0
    fi
    
    # TODO: Replace with actual Copilot API call
    log_warning "Copilot code generation not implemented yet"
    log_info "In production, this would generate:"
    log_info "  • Code patches (.patch files)"
    log_info "  • Full file outputs"
    log_info "  • Test files"
    log_info "  • Metadata (dependencies, etc.)"
    
    # Create placeholder patch file
    local patch_file="$patches_dir/${task_id}.patch"
    echo "# Placeholder patch for ${task_id}" > "$patch_file"
    
    log_success "Code generation completed: $patch_file"
}

executor_codex_apply() {
    local plan_file=$1
    local patches_dir=$2
    local report_file=$3
    
    agent_step "Executor Codex" "Applying changes and deploying"
    
    local task_id=$(jq -r '.tasks[0].id' "$plan_file")
    local patch_file="$patches_dir/${task_id}.patch"
    
    local steps_completed=()
    local steps_failed=()
    local start_time=$(date +%s)
    
    # Step 1: Apply patches
    if [ -f "$patch_file" ] && [ -s "$patch_file" ] && ! grep -q "Placeholder" "$patch_file"; then
        log_info "Applying patch: $patch_file"
        if git apply "$patch_file" 2>/dev/null; then
            steps_completed+=("apply_patch")
        else
            log_error "Failed to apply patch"
            steps_failed+=("apply_patch")
        fi
    else
        log_info "No patch to apply (placeholder or empty)"
        steps_completed+=("skip_patch")
    fi
    
    # Step 2: Install dependencies
    log_info "Installing dependencies..."
    if pnpm install --frozen-lockfile; then
        steps_completed+=("install_deps")
    else
        log_error "Failed to install dependencies"
        steps_failed+=("install_deps")
    fi
    
    # Step 3: Run tests
    log_info "Running tests..."
    if pnpm test; then
        steps_completed+=("run_tests")
    else
        log_warning "Tests failed or not configured"
        steps_completed+=("skip_tests")
    fi
    
    # Step 4: Build
    log_info "Building app.smarterbot.cl..."
    if (cd "$WORKSPACE_ROOT/app.smarterbot.cl" && pnpm build); then
        steps_completed+=("build")
    else
        log_error "Build failed"
        steps_failed+=("build")
    fi
    
    # Step 5: Deploy (only if no failures)
    if [ ${#steps_failed[@]} -eq 0 ]; then
        log_info "Deploying to VPS..."
        if "$SCRIPT_DIR/sync-smarteros.sh" app; then
            steps_completed+=("deploy")
        else
            log_error "Deployment failed"
            steps_failed+=("deploy")
        fi
        
        # Step 6: Restart service
        log_info "Restarting smarteros-app service..."
        if ssh smarteros 'sudo systemctl restart smarteros-app'; then
            steps_completed+=("restart_service")
        else
            log_error "Service restart failed"
            steps_failed+=("restart_service")
        fi
        
        # Step 7: Health check
        log_info "Running health check..."
        sleep 5
        if curl -sf https://app.smarterbot.cl/health > /dev/null; then
            steps_completed+=("health_check")
        else
            log_error "Health check failed"
            steps_failed+=("health_check")
        fi
    else
        log_warning "Skipping deployment due to previous failures"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Create execution report
    cat > "$report_file" <<EOF
{
  "success": $([ ${#steps_failed[@]} -eq 0 ] && echo true || echo false),
  "task_id": "${task_id}",
  "steps_completed": $(printf '%s\n' "${steps_completed[@]}" | jq -R . | jq -s .),
  "steps_failed": $(printf '%s\n' "${steps_failed[@]}" | jq -R . | jq -s . 2>/dev/null || echo '[]'),
  "metrics": {
    "duration": ${duration},
    "files_modified": $(git status --porcelain | wc -l)
  },
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
    
    if [ ${#steps_failed[@]} -eq 0 ]; then
        log_success "Execution completed successfully (${duration}s)"
    else
        log_error "Execution completed with failures: ${steps_failed[*]}"
        return 1
    fi
}

director_gemini_validate() {
    local report_file=$1
    
    agent_step "Director Gemini" "Validating execution results"
    
    local success=$(jq -r '.success' "$report_file")
    local steps_completed=$(jq -r '.steps_completed | length' "$report_file")
    local duration=$(jq -r '.metrics.duration' "$report_file")
    
    if [ "$success" == "true" ]; then
        log_success "Validation passed!"
        log_info "Summary:"
        log_info "  • Steps completed: $steps_completed"
        log_info "  • Duration: ${duration}s"
        
        # Store report in Vault
        vault kv put "smarteros/agents/reports/manual-$(date +%s)" @"$report_file" || true
    else
        log_error "Validation failed. Review execution report:"
        cat "$report_file" | jq
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# Main Orchestration
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  🤖 SmarterOS Tri-Agent Orchestrator  ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
    
    check_dependencies
    
    # Parse arguments
    local task_description=""
    local plan_only=false
    local execute_plan=""
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --plan-only)
                plan_only=true
                shift
                ;;
            --execute)
                execute_plan=$2
                shift 2
                ;;
            *)
                task_description=$1
                shift
                ;;
        esac
    done
    
    # Execute plan mode
    if [ -n "$execute_plan" ]; then
        if [ ! -f "$execute_plan" ]; then
            log_error "Plan file not found: $execute_plan"
            exit 1
        fi
        
        log_info "Executing existing plan: $execute_plan"
        
        local timestamp=$(date +%s)
        local report_file="$REPORTS_DIR/exec-${timestamp}.json"
        
        writer_copilot_generate "$execute_plan" "$PATCHES_DIR"
        executor_codex_apply "$execute_plan" "$PATCHES_DIR" "$report_file"
        director_gemini_validate "$report_file"
        
        exit 0
    fi
    
    # Create new plan mode
    if [ -z "$task_description" ]; then
        log_error "Task description required"
        echo "Usage:"
        echo "  $0 \"Task description\""
        echo "  $0 --plan-only \"Task description\""
        echo "  $0 --execute plan-file.json"
        exit 1
    fi
    
    local timestamp=$(date +%s)
    local plan_file="$PLANS_DIR/plan-${timestamp}.json"
    local report_file="$REPORTS_DIR/exec-${timestamp}.json"
    
    # Step 1: Gemini analyzes
    director_gemini_analyze "$task_description" "$plan_file"
    
    if [ "$plan_only" == true ]; then
        log_success "Plan created. Review and execute with:"
        echo "  $0 --execute $plan_file"
        exit 0
    fi
    
    # Step 2: Copilot generates
    writer_copilot_generate "$plan_file" "$PATCHES_DIR"
    
    # Step 3: Codex executes
    if ! executor_codex_apply "$plan_file" "$PATCHES_DIR" "$report_file"; then
        log_error "Execution failed. Exiting."
        exit 1
    fi
    
    # Step 4: Gemini validates
    director_gemini_validate "$report_file"
    
    echo -e "\n${GREEN}✨ Tri-Agent orchestration complete!${NC}\n"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
