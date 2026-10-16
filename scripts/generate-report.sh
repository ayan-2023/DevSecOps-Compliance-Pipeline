#!/usr/bin/env bash
# =============================================================================
# generate-report.sh - Consolidate security scan results into unified report
# Usage: ./scripts/generate-report.sh [--output <path>]
# =============================================================================

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORTS_DIR="${ROOT_DIR}/reports"

TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
SUMMARY_MD="${REPORTS_DIR}/security-summary.md"

echo "Generating unified DevSecOps Compliance Summary..."

cat <<EOF > "${SUMMARY_MD}"
# DevSecOps Compliance Pipeline - Security & Quality Summary

**Generated At:** ${TIMESTAMP}
**Target Repository:** DevSecOps-Compliance-Pipeline

## Scan Results Summary

| Security Scanner | Tool Purpose | Status | Details |
|---|---|---|---|
EOF

check_tool_report() {
  local tool_name="$1"
  local tool_purpose="$2"
  local dir_path="$3"

  local file_count
  file_count=$(find "${dir_path}" -type f ! -name ".gitkeep" 2>/dev/null | wc -l)

  if [ "${file_count}" -gt 0 ]; then
    echo "| **${tool_name}** | ${tool_purpose} | Generated (${file_count} reports) | See \`${dir_path#${ROOT_DIR}/}\` |" >> "${SUMMARY_MD}"
  else
    echo "| **${tool_name}** | ${tool_purpose} | Pending / No Local Artifacts | No scan output present |" >> "${SUMMARY_MD}"
  fi
}

check_tool_report "TFLint" "Terraform Linting & Rules" "${REPORTS_DIR}/tflint"
check_tool_report "TFSec" "Terraform Static Security" "${REPORTS_DIR}/tfsec"
check_tool_report "Checkov" "IaC Compliance & Policy Checks" "${REPORTS_DIR}/checkov"
check_tool_report "Gitleaks" "Secret Leak Detection" "${REPORTS_DIR}/gitleaks"
check_tool_report "Semgrep" "Custom Pattern Analysis" "${REPORTS_DIR}/semgrep"
check_tool_report "Terraform Plan" "Execution Plan Artifact" "${REPORTS_DIR}/terraform-plan"

cat <<EOF >> "${SUMMARY_MD}"

## Operational Notes
- This summary reflects reports present in the local \`reports/\` folder.
- In CI/CD (Azure DevOps), scan outputs and pipeline artifacts are published directly to pipeline runs.
- Run \`./scripts/run-security-scans.sh\` locally to populate report files before running this script.
EOF

echo "Security summary report generated at: ${SUMMARY_MD}"
