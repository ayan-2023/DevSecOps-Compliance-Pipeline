# DevSecOps Compliance Pipeline for Terraform

[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform&logoColor=white)](https://www.terraform.io/)
[![Azure DevOps](https://img.shields.io/badge/Azure_DevOps-Pipeline-0078D7?logo=azure-devops&logoColor=white)](https://azure.microsoft.com/en-us/products/devops/)
[![Security Scanners](https://img.shields.io/badge/Security-TFLint%20%7C%20TFSec%20%7C%20Checkov%20%7C%20Trivy%20%7C%20Gitleaks-critical)](docs/security-tools.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An enterprise-ready **DevSecOps Compliance & Delivery Pipeline** for Terraform Infrastructure as Code (IaC) on **Azure**. Engineered with **Azure DevOps Multi-Stage YAML Pipelines**, external reusable security templates, immutable execution plan artifacts, and manual approval gates to enforce strict governance, zero-trust secrets management, and policy compliance before cloud infrastructure provisioning.

---

## 1. Project Overview

The **DevSecOps Compliance Pipeline for Terraform** bridges the gap between infrastructure automation and corporate security compliance. By shifting security left into the pull request and build stages, this project guarantees that cloud infrastructure adheres to CIS benchmarks, corporate naming standards, and architectural baselines before a single resource is provisioned in Microsoft Azure.

---

## 2. Problem Statement

Manual security reviews of Infrastructure as Code often result in:
- **Cloud Security Drift & Breaches:** Misconfigurations such as unencrypted storage accounts or permissive network security groups slipping into production environments.
- **Accidental Secret Exposure:** Hardcoded API keys, private credentials, or connection strings committed to source control.
- **Fragile Pipeline Orchestration:** Pipelines failing prematurely when non-mandatory security tools are skipped or disabled at runtime.
- **Unverified Plan Deployments:** Running `terraform apply` directly without freezing and manually validating the exact changes planned against cloud state.

This repository provides an automated, modular, and resilient pipeline architecture designed to solve these vulnerabilities.

---

## 3. Architecture & Workflow

The pipeline separates developer repository checks from enterprise cloud delivery:
- **GitHub Actions (`.github/workflows/`):** Fast, credential-free developer feedback (formatting, linting, secret detection) during Pull Requests.
- **Azure DevOps (`pipelines/azure-pipelines.yml`):** Primary enterprise deployment pipeline with modular security stages, remote state initialization, immutable plan artifacts, and human approval gates.

```
+-------------------------------------------------------------------------------------------------------------+
|                                    AZURE DEVOPS MULTI-STAGE PIPELINE                                        |
+-------------------------------------------------------------------------------------------------------------+
                                                       │
               ┌───────────────────────────────────────┴───────────────────────────────────────┐
               ▼                                                                               ▼
  [Security Scanning Stages]                                                         [Terraform Stages]
  (External: Mausam/company-pipeline-templates)                                                │
  ├── TFLint    (templates/Tflint-scan.yml)                                                    │
  ├── TFSec     (templates/Tfsec-scan.yml)                                                     │
  ├── Checkov   (templates/Checkov-scan.yml)                                                   │
  ├── Trivy     (templates/Trivy-scan.yml)                                                     │
  └── Gitleaks  (templates/Gitleaks-scan.yml)                                                  │
               │                                                                               │
               └───────────────────────► [Terraform Init & Validate] ◄─────────────────────────┘
                                                       │
                                                       ▼
                                             [Terraform Plan]
                                         (Saves binary 'tfplan')
                                                       │
                                                       ▼
                                          [Publish Plan Artifact]
                                         ('terraform-plan' artifact)
                                                       │
                                                       ▼
                                            [Manual Approval Gate]
                                    (Server job; notifies via email)
                                                       │ (Approved on main branch)
                                                       ▼
                                             [Terraform Apply]
                                   (Downloads frozen 'terraform-plan')
                                                       │
                                                       ▼
                                          [Azure Cloud Deployment]
```

---

## 4. Key Features

- **Decoupled Security Governance:** Centralized scanner templates maintained in external repository [`Mausam/company-pipeline-templates`](https://github.com/Mausam/company-pipeline-templates).
- **Compile-Time Expression Logic:** Solves the skipped-dependency failure mode; stages dynamically adapt their `dependsOn` arrays based on enabled Boolean parameters.
- **Immutable Plan Artifact Flow:** Plan is generated once, published as a pipeline artifact, inspected during approval, and applied without re-planning.
- **Agentless Approval Gate:** Uses `ManualValidation@1` on `pool: server` to save self-hosted agent resources while awaiting sign-off.
- **Defense-in-Depth Scanning:** Multi-layered scanning combining TFLint (linting), TFSec (static analysis), Checkov (compliance policies), Trivy (misconfigurations), and Gitleaks (secret detection).
- **Dual-Platform Architecture:** Clean separation of concerns between GitHub Actions PR validation and Azure DevOps cloud provisioning.

---

## 5. Technology Stack

| Domain | Technology / Tool | Version / Standard |
|---|---|---|
| **CI/CD Platform** | Azure DevOps Pipelines | YAML Multi-Stage |
| **Source Control Gate** | GitHub Actions | Workflows v4 |
| **Infrastructure as Code** | HashiCorp Terraform | `>= 1.5.0` |
| **Cloud Target** | Microsoft Azure | AzureRM Provider `~> 3.80` |
| **Linting & Rules** | TFLint & azurerm ruleset | `v0.27.0` |
| **IaC Static Security** | TFSec | Latest CLI |
| **IaC Compliance** | Checkov (Bridgecrew) | CIS Azure Benchmark |
| **Vulnerability Scanning** | Aqua Security Trivy | Config scanner |
| **Secret Scanning** | Gitleaks | V8 Engine |
| **Custom Static Rules** | Semgrep | AST pattern rules |

---

## 6. Repository Structure

```text
DevSecOps-Compliance-Pipeline/
├── .github/
│   └── workflows/
│       ├── pull-request.yml           # Fast PR gate (fmt, backend-free validate, Gitleaks)
│       ├── release.yml                # Automated GitHub release management
│       └── terraform-security.yml     # Weekly scheduled Semgrep and Checkov audits
├── architecture/
│   ├── diagrams/
│   │   ├── pipeline-flow.mmd          # Mermaid source diagram
│   │   └── pipeline-flow.svg          # High-resolution vector architecture diagram
│   └── screenshots/                   # Visual verification artifacts
├── docs/
│   ├── deployment-guide.md            # Step-by-step Azure DevOps deployment guide
│   ├── pipeline-architecture.md       # Deep-dive into YAML stages, logic, and expressions
│   ├── project-overview.md            # Problem statement, objectives, and benefits
│   ├── security-tools.md              # Security scanner breakdown and overlap matrix
│   └── troubleshooting.md             # Common errors and tactical remediation steps
├── pipelines/
│   └── azure-pipelines.yml            # Primary Azure DevOps multi-stage CI/CD pipeline
├── policies/
│   ├── checkov/checkov.yaml           # Checkov CLI and reporting configuration
│   ├── semgrep/semgrep.yml            # Custom Semgrep static pattern rules
│   ├── tflint/.tflint.hcl             # TFLint Azure ruleset configuration
│   └── tfsec/tfsec.yml                # TFSec rule overrides and severity thresholds
├── reports/                           # Local and CI report artifact directories
│   ├── checkov/
│   ├── gitleaks/
│   ├── semgrep/
│   ├── terraform-plan/
│   ├── tflint/
│   └── tfsec/
├── scripts/
│   ├── cleanup.sh                     # Purges transient plan and state files
│   ├── generate-report.sh             # Aggregates scan results into summary reports
│   └── run-security-scans.sh          # Local developer security scan orchestrator
├── terraform/
│   ├── main.tf                        # Azure Resource Group & Hardened Storage Account
│   ├── outputs.tf                     # Provisioned resource identifiers
│   ├── providers.tf                   # Terraform AzureRM provider and backend declaration
│   ├── terraform.tfvars.example       # Example variable definitions
│   └── variables.tf                   # Variable declarations with typing and defaults
├── .gitignore                         # Comprehensive ignore rules
├── LICENSE                            # MIT License
└── README.md                          # Project documentation entry point
```

---

## 7. Security Tools & Purpose

| Security Tool | Purpose | Policy File | Template Reference |
|---|---|---|---|
| **TFLint** | Terraform code quality and Azure-specific conventions | [policies/tflint/.tflint.hcl](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/tflint/.tflint.hcl) | `templates/Tflint-scan.yml@secureTemplates` |
| **TFSec** | High-speed static analysis for cloud misconfigurations | [policies/tfsec/tfsec.yml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/tfsec/tfsec.yml) | `templates/Tfsec-scan.yml@secureTemplates` |
| **Checkov** | Compliance scanning against CIS benchmarks and policies | [policies/checkov/checkov.yaml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/checkov/checkov.yaml) | `templates/Checkov-scan.yml@secureTemplates` |
| **Trivy** | Configuration vulnerability scanning | Default configuration | `templates/Trivy-scan.yml@secureTemplates` |
| **Gitleaks** | Detection of hardcoded API keys, secrets, and credentials | Git history & directory | `templates/Gitleaks-scan.yml@secureTemplates` |
| **Semgrep** | Custom AST pattern matching for organizational rules | [policies/semgrep/semgrep.yml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/policies/semgrep/semgrep.yml) | Integrated in GitHub Actions & Local Scans |
| **Terraform Validate** | Syntax and internal configuration consistency | Native engine | Inline Task |

For an in-depth comparison of scanner capabilities and overlap analysis, refer to [docs/security-tools.md](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/docs/security-tools.md).

---

## 8. Azure DevOps Pipeline Execution

The pipeline is defined in [pipelines/azure-pipelines.yml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/pipelines/azure-pipelines.yml).

### Runtime Parameters
When queuing a run, engineers can customize execution using Boolean switches:
- `Tflint` (default: `true`)
- `TFsec` (default: `true`)
- `Checkov` (default: `true`)
- `Trivy` (default: `true`)
- `Gitleaks` (default: `true`)
- `terraformValidate` (default: `true`)
- `terraformPlan` (default: `true`)
- `terraformApply` (default: `true`)

### Pipeline Prerequisites
- **Agent Pool:** `Mausam agent` (self-hosted build agent)
- **Variable Group:** `Mausam-variable-group` containing backend credentials and service connections
- **External Repository:** `Mausam/company-pipeline-templates` (alias: `secureTemplates`)

---

## 9. Pull Request & Branching Strategy

- **Feature Branches (`feature/*`):**
  - Triggers fast GitHub Actions validation on PR (`terraform fmt`, `terraform validate`, Gitleaks).
  - Triggers Azure DevOps security scans and generates `terraform-plan` artifact.
  - The Apply stage is **strictly skipped** on non-main branches.
- **Main Branch (`main`):**
  - Triggers the full pipeline: Security Scans → Init & Validate → Plan → Manual Approval Gate → Production Apply.

---

## 10. Terraform Plan and Apply Process

1. **Planning (`terraformPlan`):**
   - Initializes backend using remote Azure Blob storage.
   - Executes `terraform plan -out=$(workingDirectory)/tfplan`.
   - Publishes `tfplan` as pipeline artifact `terraform-plan`.
2. **Approval Gate (`manualApproval`):**
   - Pauses execution and dispatches email notification to `ayanjana2026@gmail.com`.
   - Halts progression until authorized review is completed.
3. **Applying (`terraformApplyJob`):**
   - Downloads `terraform-plan` to `$(Pipeline.Workspace)/terraform-plan`.
   - Re-initializes provider backend.
   - Executes `terraform apply $(Pipeline.Workspace)/terraform-plan/tfplan` ensuring zero deviation from the inspected plan.

---

## 11. Local Developer Workflow & Scripts

Developers can execute scans locally before pushing changes:

```bash
# 1. Execute all security scans locally
./scripts/run-security-scans.sh

# 2. Consolidate scan outputs into a Markdown summary
./scripts/generate-report.sh

# 3. Clean transient files and plan artifacts
./scripts/cleanup.sh
```

---

## 12. Security Best Practices Enforced

- **Zero Plaintext Secrets:** No credentials stored in Git, YAML, or logs.
- **Least Privilege:** Azure DevOps uses dedicated Service Connections with scoped RBAC.
- **Explicit TLS & HTTPS:** Hardened Azure Storage baseline requiring TLS 1.2 and denying anonymous access.
- **Fail-Safe Approvals:** Manual validation times out automatically after 24 hours (`onTimeout: reject`).

---

## 13. Troubleshooting & Operations

Refer to [docs/troubleshooting.md](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/docs/troubleshooting.md) for detailed remediation steps regarding:
- Cross-repository template authorization errors.
- Self-hosted agent connectivity and missing CLI paths.
- Azure remote state access and permission issues.
- Missing plan artifact or mismatched download paths.

---

## 14. Limitations & Future Roadmap

- **Semgrep Azure DevOps Integration:** Semgrep currently executes in GitHub Actions and local scripts; external template integration in Azure DevOps is planned once template YAML is supplied.
- **Automated Cost Estimation:** Integration of Infracost to display financial impact in pull request comments.
- **Environment Checks Transition:** Optional future upgrade from `ManualValidation@1` to Azure DevOps Environment approvals for multi-environment gating (Dev → Staging → Prod).
