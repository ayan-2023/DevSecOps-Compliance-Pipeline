# DevSecOps Pipeline Troubleshooting Guide

This guide provides practical diagnoses and resolutions for common failure modes encountered across pipeline execution, repository authentication, agent provisioning, and cloud deployment.

---

## 1. External Template Repository Issues

### Symptom: `Repository secureTemplates could not be resolved` or `Access Denied`
- **Cause:** Azure DevOps build service lacks read permissions to repository `Mausam/company-pipeline-templates` or the repository declaration syntax is incorrect.
- **Resolution:**
  1. Verify the `resources.repositories` declaration in [azure-pipelines.yml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/pipelines/azure-pipelines.yml):
     ```yaml
     resources:
       repositories:
         - repository: secureTemplates
           type: git
           name: Mausam/company-pipeline-templates
           ref: refs/heads/main
     ```
  2. Navigate to **Project Settings → Repositories → Mausam/company-pipeline-templates → Security**.
  3. Grant **Read** permission to `<ProjectName> Build Service (<OrgName>)` and `Project Collection Build Service`.
  4. Ensure pipeline authorization prompts in the run UI have been marked **Permit**.

### Symptom: `Template not found: templates/Tflint-scan.yml@secureTemplates`
- **Cause:** Incorrect file path, branch reference, or case-sensitive file name mismatch in the external repository.
- **Resolution:**
  - Verify exact filename casing in `Mausam/company-pipeline-templates`:
    - `templates/Tflint-scan.yml` (capital `T`)
    - `templates/Tfsec-scan.yml` (capital `T`)
    - `templates/Checkov-scan.yml` (capital `C`)
    - `templates/Trivy-scan.yml` (capital `T`)
    - `templates/Gitleaks-scan.yml` (capital `G`)

---

## 2. Agent Pool & Execution Failures

### Symptom: `No agent found in pool Mausam agent which satisfies the specified demands`
- **Cause:** Self-hosted agent is offline, unassigned to pool `Mausam agent`, or lacking capability requirements.
- **Resolution:**
  1. Open **Project Settings → Agent pools → Mausam agent**.
  2. Verify that at least one agent is in the **Online** and **Idle** state.
  3. If running locally, start the agent listener service:
     ```powershell
     cd C:\agent
     .\run.cmd
     ```

### Symptom: `tflint: command not found` or `checkov: command not found`
- **Cause:** Security scanning binaries are not installed on the agent host or are omitted from the system environment variable `PATH`.
- **Resolution:**
  1. Log into the agent machine and confirm CLI presence:
     ```powershell
     tflint --version
     tfsec --version
     checkov --version
     trivy --version
     gitleaks version
     ```
  2. If newly installed, restart the Azure DevOps Agent service to reload the system `PATH`.

---

## 3. Terraform Backend & Authentication Failures

### Symptom: `Error: Failed to get existing workspaces: ContainersClient.URLForContainer`
- **Cause:** The Azure Storage container, storage account, or resource group specified in `Mausam-variable-group` does not exist or has incorrect access credentials.
- **Resolution:**
  1. Check variable group settings:
     - `backendAzureRmResourceGroupName`
     - `backendAzureRmStorageAccountName`
     - `backendAzureRmContainerName`
     - `backendAzureRmKey`
  2. Confirm that the Azure DevOps Service Connection (`backendServiceArm`) has `Contributor` or `Storage Blob Data Contributor` permissions on the storage account.

### Symptom: `AuthorizationFailed: The client with object id does not have authorization to perform action`
- **Cause:** The Service Principal associated with `environmentServiceNameAzureRM` lacks role assignments on the target subscription or resource group.
- **Resolution:**
  - In Azure Portal, navigate to the target subscription → **Access control (IAM)** → Add **Contributor** role assignment for the service principal.

---

## 4. Terraform Plan & Artifact Download Failures

### Symptom: `Artifact terraform-plan was not found for build`
- **Cause:** The plan stage was skipped, failed prior to artifact publication, or the artifact name was misspelled.
- **Resolution:**
  1. Check if `terraformPlan` stage succeeded.
  2. Confirm that `PublishPipelineArtifact@1` executed:
     ```yaml
     - task: PublishPipelineArtifact@1
       inputs:
         targetPath: '$(workingDirectory)/tfplan'
         artifact: 'terraform-plan'
     ```

### Symptom: `Failed to load "tfplan" as a plan file` or `File not found: .../tfplan`
- **Cause:** Working directory discrepancy between where the plan artifact was downloaded and where `terraform apply` expects it.
- **Resolution:**
  - Verify that `DownloadPipelineArtifact@2` downloads to:
    `targetPath: '$(Pipeline.Workspace)/terraform-plan'`
  - And `TerraformTask@5 Apply` specifies:
    `commandOptions: '$(Pipeline.Workspace)/terraform-plan/tfplan'`

---

## 5. Manual Approval & Deployment Gate Issues

### Symptom: `terraformApply` Stage Skipped on `feature/*` Branches
- **Cause:** Working as intended by design!
- **Explanation:**
  The apply stage condition strictly mandates:
  ```yaml
  condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
  ```
  Only merges into `main` are authorized to deploy. Feature branches terminate safely after plan generation.

### Symptom: `ManualValidation@1 timed out after 1440 minutes`
- **Cause:** No authorized user approved the prompt within the 24-hour timeout window.
- **Resolution:**
  - By design, `onTimeout: 'reject'` causes the job to fail safely, aborting the apply job. Re-trigger the pipeline run when ready to approve.

### Symptom: `terraformInit` Skipped When Some Security Scans Are Disabled
- **Cause:** Previously caused by hardcoded static `dependsOn` lists.
- **Resolution:**
  - Fixed via compile-time expression logic (`${{ if eq(parameters.<tool>, true) }}:`). Ensure you are using the updated [azure-pipelines.yml](file:///d:/DevOps%20Coding/DevSecOps-Compliance-Pipeline/pipelines/azure-pipelines.yml).
