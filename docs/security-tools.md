# Security Tools & Compliance Matrix

This document provides a detailed breakdown of all security and static analysis tools utilized within the **DevSecOps Compliance Pipeline for Terraform**.

---

## 1. Tool Governance Matrix

| Tool | Primary Purpose | Policy Configuration Location | Pipeline Template Location | Invocation Method | Local / CI Output Location | Status |
|---|---|---|---|---|---|---|
| **TFLint** | Terraform linting, deprecated syntax & Azure ruleset | `policies/tflint/.tflint.hcl` | `Mausam/company-pipeline-templates`<br/>(`templates/Tflint-scan.yml`) | CLI / Azure DevOps Task | `reports/tflint/` | **Implemented** |
| **TFSec** | Terraform security & misconfiguration analysis | `policies/tfsec/tfsec.yml` | `Mausam/company-pipeline-templates`<br/>(`templates/Tfsec-scan.yml`) | CLI / Azure DevOps Task | `reports/tfsec/` | **Implemented** |
| **Checkov** | IaC compliance, CIS benchmarks & framework audits | `policies/checkov/checkov.yaml` | `Mausam/company-pipeline-templates`<br/>(`templates/Checkov-scan.yml`) | CLI / Azure DevOps Task | `reports/checkov/` | **Implemented** |
| **Trivy** | IaC misconfiguration & vulnerability scanning | CLI flags / default rulebase | `Mausam/company-pipeline-templates`<br/>(`templates/Trivy-scan.yml`) | CLI / Azure DevOps Task | `reports/` (JSON) | **Implemented** |
| **Gitleaks** | High-entropy secret & credential detection | Default rulebase + Git history | `Mausam/company-pipeline-templates`<br/>(`templates/Gitleaks-scan.yml`) | CLI / Azure DevOps Task / GitHub Action | `reports/gitleaks/` | **Implemented** |
| **Semgrep** | Custom AST static pattern analysis | `policies/semgrep/semgrep.yml` | Local policy / GitHub Actions workflow | Docker / CLI / GitHub Action | `reports/semgrep/` | **Implemented in GitHub Actions & Local; Azure DevOps Template Pending** |
| **Terraform Validate** | Internal syntax and argument consistency | Native Terraform engine | Inline pipeline task | `terraform validate` | Pipeline step log | **Implemented** |

---

## 2. Tool Details & Functional Analysis

### 2.1. TFLint
- **Role:** Pluggable Terraform linter that verifies provider-specific rules and syntax errors that `terraform validate` misses (e.g., invalid Azure VM instance types or storage naming conventions).
- **Configuration:** [policies/tflint/.tflint.hcl](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/tflint/.tflint.hcl).
- **Azure DevOps Template:** `templates/Tflint-scan.yml@secureTemplates`.
- **Command Invocation:**
  ```bash
  tflint --recursive --force
  ```

### 2.2. TFSec
- **Role:** Fast static analysis security scanner designed specifically for Terraform code. Parses HCL code into an abstract syntax tree and evaluates it against security best practices (e.g., unrestricted network access, missing encryption).
- **Configuration:** [policies/tfsec/tfsec.yml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/tfsec/tfsec.yml).
- **Azure DevOps Template:** `templates/Tfsec-scan.yml@secureTemplates`.
- **Command Invocation:**
  ```bash
  tfsec .
  ```

### 2.3. Checkov
- **Role:** Policy-as-code enforcement tool for infrastructure as code. Validates compliance against industry standards including CIS Azure Foundations Benchmark, NIST, and HIPAA.
- **Configuration:** [policies/checkov/checkov.yaml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/checkov/checkov.yaml).
- **Azure DevOps Template:** `templates/Checkov-scan.yml@secureTemplates`.
- **Command Invocation:**
  ```bash
  checkov -d . ; exit 0
  ```

### 2.4. Trivy
- **Role:** Comprehensive security scanner covering container images, Git repositories, and IaC configurations. Scans Terraform code for known CVEs and configuration issues.
- **Azure DevOps Template:** `templates/Trivy-scan.yml@secureTemplates`.
- **Command Invocation:**
  ```bash
  trivy config . ; exit 0
  ```

### 2.5. Gitleaks
- **Role:** Fast, regex-based secret scanner that inspects uncommitted working directories and Git commit history for API keys, private certificates, AWS/Azure access tokens, and passwords.
- **Azure DevOps Template:** `templates/Gitleaks-scan.yml@secureTemplates`.
- **Command Invocation:**
  ```bash
  gitleaks dir . ; exit 0
  ```
- **PR Gate:** Also integrated in `.github/workflows/pull-request.yml` for immediate rejection of PRs introducing secret tokens.

### 2.6. Semgrep
- **Role:** Fast, lightweight static analysis engine for finding bugs and enforcing custom internal security policies using pattern-matching syntax.
- **Configuration:** [policies/semgrep/semgrep.yml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/semgrep/semgrep.yml).
- **Status:** Integrated in `.github/workflows/terraform-security.yml` and local script `scripts/run-security-scans.sh`. Azure DevOps stage will be added once external template is supplied by the architecture team.

---

## 3. Overlap Analysis: TFSec vs. Checkov vs. Trivy

Engineers often notice that **TFSec**, **Checkov**, and **Trivy** all scan Terraform code. While there is overlap, each tool delivers distinct strengths:

```
┌────────────────────────────────────────────────────────┐
│                      Overlap Area                      │
│        (Basic Azure IaC Misconfiguration Checks)       │
├─────────────────────┬──────────────────┬───────────────┤
│        TFSec        │     Checkov      │     Trivy     │
├─────────────────────┼──────────────────┼───────────────┤
│ • Native HCL parser │ • CIS Benchmarks │ • Multi-target│
│ • Blazing fast      │ • Frameworks     │   (IaC, SBOM, │
│ • Terraform-focused │   (NIST, HIPAA)  │    CVE, OS)   │
│ • Developer CLI     │ • Graph & module │ • Container & │
│   ergonomics        │   context logic  │   binary scan │
└─────────────────────┴──────────────────┴───────────────┘
```

### Defense-in-Depth Rationale:
1. **Rule Diversity:** Checkov excels at multi-resource graph analysis (evaluating whether a Security Group is properly linked to a Network Interface). TFSec offers deep HCL-specific checks. Trivy correlates configuration issues with known CVE databases.
2. **False Positive Balancing:** Discrepancies between scanners help security teams identify edge cases that single scanners overlook.
3. **Parameter Modularity:** Teams can independently toggle scanners on or off using the pipeline's runtime parameters without impacting pipeline flow.
