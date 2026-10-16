# Project Overview: DevSecOps Compliance Pipeline for Terraform

## 1. Executive Summary

The **DevSecOps Compliance Pipeline for Terraform** is an enterprise-grade automated delivery framework engineered to shift security, compliance, quality, and secret detection left into the Infrastructure as Code (IaC) lifecycle. 

Operating primarily on **Azure DevOps** with complementary **GitHub Actions** workflows for repository-level developer feedback, this project eliminates manual compliance bottlenecks, prevents drift and misconfigurations, and enforces strict release governance through automated policy verification and manual approval gates.

---

## 2. Problem Statement & Motivation

Traditional cloud infrastructure management faces critical challenges when scaling across teams:
1. **Late Security Discovery:** Infrastructure security vulnerabilities (e.g., exposed storage accounts, unencrypted disks, open network security groups) are often discovered post-deployment or during perimeter audits.
2. **Secret Leakage:** API tokens, private keys, and Azure service principal credentials inadvertently committed to Git repositories pose severe threat vectors.
3. **Inconsistent Syntax & Quality:** Divergent formatting, outdated provider configurations, and unvalidated variables degrade codebase maintainability.
4. **Plan-Apply Drift:** Running `terraform apply` directly against cloud environments without an immutable, pre-approved execution plan introduces unpredictable state drift and operational downtime.
5. **Coupled & Fragile Pipelines:** Monolithic CI/CD pipelines fail entirely when individual security tools are toggled or optional, blocking critical validation and planning.

---

## 3. Core Objectives & Scope

| Objective | Architectural Mechanism | Implementation Status |
|---|---|---|
| **Shift-Left Static Security** | Scan Terraform configurations using TFLint, TFSec, Checkov, Trivy, and Semgrep before cloud provisioning | **Implemented** (Azure DevOps + GitHub Actions) |
| **Zero Secret Exposure** | High-entropy Git history and directory scanning using Gitleaks | **Implemented** |
| **Centralized Governance** | Decoupled pipeline templates hosted in external repository `Mausam/company-pipeline-templates` | **Implemented** |
| **Independent Scan Toggling** | Boolean runtime parameters with compile-time YAML expressions | **Implemented** |
| **Deterministic Deployment** | Generate, freeze, and publish `tfplan` artifact; enforce manual approval prior to apply | **Implemented** |
| **Zero Inlined Credentials** | Dynamic Azure Service Principal authentication through Azure DevOps Service Connections and Variable Groups | **Implemented** |

---

## 4. Architectural Components

```
DevSecOps-Compliance-Pipeline/
├── .github/workflows/          # Fast GitHub developer feedback (PR lint, validate, secret check)
├── architecture/
│   ├── diagrams/              # Mermaid (.mmd) and vector (.svg) pipeline architecture diagrams
│   └── screenshots/           # Pipeline execution and artifact screenshots
├── docs/                      # Comprehensive technical and operational guides
│   ├── project-overview.md
│   ├── pipeline-architecture.md
│   ├── security-tools.md
│   ├── deployment-guide.md
│   └── troubleshooting.md
├── pipelines/
│   └── azure-pipelines.yml    # Primary Azure DevOps multi-stage CI/CD pipeline
├── policies/                  # Centralized scanner rule configurations
│   ├── checkov/
│   ├── semgrep/
│   ├── tflint/
│   └── tfsec/
├── reports/                   # Dedicated output directories for local/CI scan artifacts
├── scripts/                   # Local automation for developers (scans, reports, cleanup)
└── terraform/                 # Hardened Azure Infrastructure as Code definitions
```

---

## 5. Key Design Decisions

### 5.1. Separation of Concerns (CI/CD Platforms)
- **Azure DevOps (`pipelines/azure-pipelines.yml`)**: Designated as the **primary enterprise delivery engine**. Manages cloud authentication, state backend persistence, external security template execution, artifact publication, production approval gates, and infrastructure deployment.
- **GitHub Actions (`.github/workflows/`)**: Serves as the **local repository quality gate**. Runs lightweight, zero-cloud-credential checks (`terraform fmt`, `terraform validate -backend=false`, and Gitleaks) on Pull Requests to give immediate developer feedback before Azure DevOps triggers.

### 5.2. External Pipeline Template Repository
Security scanning templates are decoupled into `Mausam/company-pipeline-templates`. This architecture ensures:
- Reusability across multiple infrastructure repositories within the organization.
- Centralized security maintenance (updating scanner arguments or compliance policies without touching application repositories).
- Clean repository boundaries adhering to corporate DevSecOps compliance models.

### 5.3. Dynamic Compile-Time Dependencies
Rather than hardcoding static `dependsOn` lists that break when optional stages are skipped, the pipeline utilizes Azure DevOps compile-time expression logic (`${{ if eq(parameters.<tool>, true) }}:`). This guarantees that disabling a scanner never blocks `terraformInit` or `terraformPlan`.

### 5.4. Immutable Plan-to-Apply Artifact Pattern
The pipeline prohibits blind `terraform apply -auto-approve`. Instead:
1. `terraformPlan` produces a frozen binary plan file (`tfplan`).
2. The plan is published as a pipeline artifact (`terraform-plan`).
3. An agentless server job (`ManualValidation@1`) halts execution and notifies authorized approvers.
4. Approvers inspect the exact plan artifact.
5. Upon approval, `terraformApplyJob` downloads the identical artifact and executes `terraform apply tfplan`.

---

## 6. Business & Operational Benefits

- **Auditability:** Complete traceability from commit to security scan, plan approval, and cloud deployment.
- **Cost Reduction:** Prevents provisioning accidental oversized or misconfigured resources before deployment.
- **Risk Mitigation:** Proactively blocks common cloud vulnerabilities (CWE, OWASP Top 10 for Cloud) at commit and PR stages.
- **Operational Agility:** Modular parameters allow engineers to run targeted scans or validation cycles without running the entire deployment cycle.
