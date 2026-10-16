# Deployment & Operations Guide

This guide details the step-by-step setup, configuration prerequisites, security authorization, and execution procedures for the **DevSecOps Compliance Pipeline for Terraform**.

---

## 1. Prerequisites Checklist

Before executing the pipeline, ensure the following Azure DevOps and cloud prerequisites are in place:

- [ ] **Azure DevOps Project:** Active Azure DevOps organization and project.
- [ ] **Self-Hosted Agent Pool:** An agent pool named `Mausam agent` with online build agents having Terraform, Git, and security tool CLIs installed.
- [ ] **External Template Repository Authorization:** Read access granted to the external repository `Mausam/company-pipeline-templates`.
- [ ] **Azure Resource Manager Service Connection:** A validated Azure DevOps ARM service connection (referenced via variable `environmentServiceNameAzureRM` / `backendServiceArm`).
- [ ] **Variable Group:** A variable group named `Mausam-variable-group` linked to the pipeline.
- [ ] **Azure Remote State Backend:** Pre-provisioned Azure Resource Group, Storage Account, and Blob Container for Terraform state locking and persistence.

---

## 2. Variable Group Configuration (`Mausam-variable-group`)

Navigate to **Azure DevOps → Pipelines → Library → Variable groups** and verify the following variables inside `Mausam-variable-group`:

| Variable Name | Example Value / Purpose | Is Secret? |
|---|---|---|
| `backendServiceArm` | `Mausam-azure-devops` (ARM Service Connection Name) | No |
| `backendAzureRmResourceGroupName` | `rg-terraform-state-prod` | No |
| `backendAzureRmStorageAccountName` | `sttfstateprod001` | No |
| `backendAzureRmContainerName` | `tfstate` | No |
| `backendAzureRmKey` | `devsecops-compliance.tfstate` | No |
| `environmentServiceNameAzureRM` | `Mausam-azure-devops` (ARM Service Connection Name) | No |
| `workingDirectory` | `$(System.DefaultWorkingDirectory)/terraform` | No |

> [!IMPORTANT]
> Never commit service principal keys, client secrets, or subscription passwords into Git or plaintext pipeline variables. Always use Azure DevOps Service Connections with Workload Identity Federation or managed secrets.

---

## 3. External Template Repository Authorization

The pipeline references reusable templates hosted in `Mausam/company-pipeline-templates`:

```yaml
resources:
  repositories:
    - repository: secureTemplates
      type: git
      name: Mausam/company-pipeline-templates
      ref: refs/heads/main
```

### Authorization Procedure:
1. When triggering the pipeline for the first time, Azure DevOps will display a banner:  
   *"A pipeline needs permission to access a resource before this run can continue."*
2. Click **View** and select **Permit** to authorize cross-repository access.
3. In **Project Settings → Repositories → Mausam/company-pipeline-templates → Security**, ensure the build service account (*`<ProjectName> Build Service`*) has **Read** permission.

---

## 4. Self-Hosted Agent Pool Configuration (`Mausam agent`)

The pipeline runs agent jobs on the pool:
```yaml
pool:
  name: 'Mausam agent'
```

### Tooling Requirements on Agent Machine:
Ensure the host agent operating system has the following binaries installed and available in the system `PATH`:
- **Terraform:** `>= 1.5.0`
- **Git:** `>= 2.30`
- **PowerShell:** `7.x` or Windows PowerShell `5.1`
- **TFLint:** `tflint --version`
- **TFSec:** `tfsec --version`
- **Checkov:** `checkov --version`
- **Trivy:** `trivy --version`
- **Gitleaks:** `gitleaks version`

---

## 5. Pipeline Execution Workflow

### 5.1. Triggering a Run
1. Go to **Azure DevOps → Pipelines → DevSecOps-Compliance-Pipeline**.
2. Click **Run pipeline**.
3. In the run dialogue, review the runtime parameters:
   - Toggle individual security scanners (`Tflint`, `TFsec`, `Checkov`, `Trivy`, `Gitleaks`).
   - Confirm `terraformValidate`, `terraformPlan`, and `terraformApply` settings.
4. Select the target branch:
   - Feature branches (`feature/*`): Runs security scans, validation, and generates a plan artifact. Apply stage is skipped.
   - Main branch (`main`): Runs all stages, including the manual approval gate and production deployment.
5. Click **Run**.

---

## 6. Manual Approval Procedure

When a build runs on `main` and reaches the `terraformApply` stage:
1. The server job `manualApproval` activates without consuming agent capacity.
2. An automated email is dispatched to `ayanjana2026@gmail.com`.
3. The designated approver navigates to the pipeline run summary page.
4. Click on the **Manual Validation** task or the **Needs Approval** indicator.
5. Download and review the `terraform-plan` artifact from the **Related → Published artifacts** tab.
6. Verify that the planned resource changes match approved change requests.
7. Click **Resume** to authorize deployment, or **Reject** to abort the release.

---

## 7. Deployment Verification

After `terraformApplyJob` completes:
1. Check pipeline step logs for `TerraformTask@5 Apply Approved Plan`.
2. Verify exit status: `Apply complete! Resources: X added, 0 changed, 0 destroyed.`
3. In the Azure Portal:
   - Navigate to the resource group specified in `var.resource_group_name`.
   - Verify that the storage account is created with `Standard_GRS`, HTTPS traffic enforced, minimum TLS version set to `1.2`, and public blob access disabled.
