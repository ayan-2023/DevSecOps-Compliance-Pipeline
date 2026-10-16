#!/usr/bin/env bash
# =============================================================================
# run-security-scans.sh - Run local DevSecOps security and compliance scanners
# Usage: ./scripts/run-security-scans.sh [--tool <tool-name>] [--fail-fast]
# Supported tools: tflint, tfsec, checkov, trivy, gitleaks, semgrep
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

TERRAFORM_DIR="${ROOT_DIR}/terraform"
REPORTS_DIR="${ROOT_DIR}/reports"
POLICIES_DIR="${ROOT_DIR}/policies"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
SCAN_FAILURES=0

log_info() {
  echo -e "\033[1;34m[INFO]\033[0m $1"
}

log_warn() {
  echo -e "\033[1;33m[WARN]\033[0m $1"
}

log_error() {
  echo -e "\033[1;31m[ERROR]\033[0m $1"
}

log_success() {
  echo -e "\033[1;32m[SUCCESS]\033[0m $1"
}

# 1. TFLint
run_tflint() {
  log_info "Running TFLint..."
  if command -v tflint &>/dev/null; then
    tflint --init --config="${POLICIES_DIR}/tflint/.tflint.hcl" || true
    if tflint --config="${POLICIES_DIR}/tflint/.tflint.hcl" --recursive "${TERRAFORM_DIR}" > "${REPORTS_DIR}/tflint/tflint-report-${TIMESTAMP}.txt"; then
      log_success "TFLint check passed."
    else
      log_warn "TFLint found issues. Output saved to reports/tflint/tflint-report-${TIMESTAMP}.txt"
      SCAN_FAILURES=$((SCAN_FAILURES + 1))
    fi
  else
    log_warn "tflint CLI not installed or not in PATH. Skipping TFLint."
  fi
}

# 2. TFSec
run_tfsec() {
  log_info "Running TFSec..."
  if command -v tfsec &>/dev/null; then
    if tfsec "${TERRAFORM_DIR}" --config-file "${POLICIES_DIR}/tfsec/tfsec.yml" --format json --out "${REPORTS_DIR}/tfsec/tfsec-report-${TIMESTAMP}.json"; then
      log_success "TFSec check passed."
    else
      log_warn "TFSec found vulnerabilities. Output saved to reports/tfsec/tfsec-report-${TIMESTAMP}.json"
      SCAN_FAILURES=$((SCAN_FAILURES + 1))
    fi
  else
    log_warn "tfsec CLI not installed or not in PATH. Skipping TFSec."
  fi
}

# 3. Checkov
run_checkov() {
  log_info "Running Checkov..."
  if command -v checkov &>/dev/null; then
    if checkov --config-file "${POLICIES_DIR}/checkov/checkov.yaml" --output json --output-file-path "${REPORTS_DIR}/checkov"; then
      log_success "Checkov check passed."
    else
      log_warn "Checkov detected policy violations. Check reports/checkov for details."
      SCAN_FAILURES=$((SCAN_FAILURES + 1))
    fi
  else
    log_warn "checkov CLI not installed or not in PATH. Skipping Checkov."
  fi
}

# 4. Trivy
run_trivy() {
  log_info "Running Trivy configuration scan..."
  if command -v trivy &>/dev/null; then
    if trivy config "${TERRAFORM_DIR}" --format json --output "${REPORTS_DIR}/trivy-report-${TIMESTAMP}.json"; then
      log_success "Trivy check passed."
    else
      log_warn "Trivy detected misconfigurations. Output saved to reports/trivy-report-${TIMESTAMP}.json"
      SCAN_FAILURES=$((SCAN_FAILURES + 1))
    fi
  else
    log_warn "trivy CLI not installed or not in PATH. Skipping Trivy."
  fi
}

# 5. Gitleaks
run_gitleaks() {
  log_info "Running Gitleaks secret detection..."
  if command -v gitleaks &>/dev/null; then
    if gitleaks detect --source="${ROOT_DIR}" --report-path="${REPORTS_DIR}/gitleaks/gitleaks-report-${TIMESTAMP}.json" --verbose; then
      log_success "Gitleaks detected no secrets."
    else
      log_error "Gitleaks detected potential secret leaks! Report saved to reports/gitleaks/gitleaks-report-${TIMESTAMP}.json"
      SCAN_FAILURES=$((SCAN_FAILURES + 1))
    fi
  else
    log_warn "gitleaks CLI not installed or not in PATH. Skipping Gitleaks."
  fi
}

# 6. Semgrep
run_semgrep() {
  log_info "Running Semgrep static analysis..."
  if command -v semgrep &>/dev/null; then
    if semgrep scan --config="${POLICIES_DIR}/semgrep/semgrep.yml" "${TERRAFORM_DIR}" --json --output="${REPORTS_DIR}/semgrep/semgrep-report-${TIMESTAMP}.json"; then
      log_success "Semgrep check passed."
    else
      log_warn "Semgrep detected policy matches. Report saved to reports/semgrep/semgrep-report-${TIMESTAMP}.json"
      SCAN_FAILURES=$((SCAN_FAILURES + 1))
    fi
  else
    log_warn "semgrep CLI not installed or not in PATH. Skipping Semgrep."
  fi
}

# Execution
echo "======================================================"
echo " Starting Local DevSecOps Scans (${TIMESTAMP}) "
echo "======================================================"

run_tflint
run_tfsec
run_checkov
run_trivy
run_gitleaks
run_semgrep

echo "======================================================"
if [ ${SCAN_FAILURES} -eq 0 ]; then
  log_success "All security checks finished cleanly with 0 failures."
  exit 0
else
  log_warn "Security checks completed with ${SCAN_FAILURES} tool findings."
  exit ${SCAN_FAILURES}
fi
