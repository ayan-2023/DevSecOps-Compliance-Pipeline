#!/usr/bin/env bash
# =============================================================================
# cleanup.sh - Clean transient Terraform artifacts, cache, and scan reports
# Usage: ./scripts/cleanup.sh [--all]
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== Starting workspace cleanup in: ${ROOT_DIR} ==="

# Clean Terraform transient files
echo "Cleaning Terraform cache and local state files..."
find "${ROOT_DIR}/terraform" -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
find "${ROOT_DIR}/terraform" -type f -name ".terraform.lock.hcl" -exec rm -f {} + 2>/dev/null || true
find "${ROOT_DIR}/terraform" -type f -name "*.tfstate" -exec rm -f {} + 2>/dev/null || true
find "${ROOT_DIR}/terraform" -type f -name "*.tfstate.*" -exec rm -f {} + 2>/dev/null || true
find "${ROOT_DIR}/terraform" -type f -name "*.tfplan" -exec rm -f {} + 2>/dev/null || true
find "${ROOT_DIR}/terraform" -type f -name "tfplan" -exec rm -f {} + 2>/dev/null || true

# Clean generated reports while preserving .gitkeep files
echo "Cleaning transient security scan reports..."
for report_dir in "${ROOT_DIR}/reports"/*; do
  if [ -d "${report_dir}" ]; then
    find "${report_dir}" -type f ! -name ".gitkeep" -exec rm -f {} + 2>/dev/null || true
  fi
done

echo "=== Workspace cleanup completed successfully ==="
