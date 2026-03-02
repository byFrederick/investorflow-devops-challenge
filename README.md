# InvestorFlow DevOps Challenge
Azure platform provisioning and Kubernetes delivery implemented with Terraform, GitHub Actions, `task`, and `werf`.

## Table of Contents
- [Architecture Summary](#architecture-summary)
- [Repository Layout](#repository-layout)
- [Toolchain Baseline](#toolchain-baseline)
- [Terraform Runtime Model](#terraform-runtime-model)
- [Application Delivery Configuration](#application-delivery-configuration)
- [GitHub Actions Pipelines](#github-actions-pipelines)
- [Promotion Flow](#promotion-flow)
- [Identity and Permissions](#identity-and-permissions)
- [Local Execution Parity](#local-execution-parity)
- [Important Note](#important-note)

## Architecture Summary
- Cloud: Azure, single codebase deployed to `dev`, `qa`, `stg`, `prd`.
- IaC: Terraform with `azurerm` backend and workspace-driven environment isolation.
- Compute: AKS (`Azure/aks/azurerm`) with Azure CNI overlay, OIDC issuer, AAD RBAC.
- Registry: ACR (`Azure/avm-res-containerregistry-registry/azurerm`) attached to AKS.
- Networking: VNet (`Azure/avm-res-network-virtualnetwork/azurerm`) + dedicated AKS subnet.
- Delivery: `task deploy` orchestrates Azure auth, kubeconfig acquisition, and `werf converge`.
- CI/CD: GitHub Actions split into validation (PR) and promotion (manual dispatch) pipelines.

## Repository Layout
```text
.github/workflows/   # terraform/app validation + apply/deploy workflows
terraform/           # backend/providers/locals/modules/outputs
app/werf.yaml        # werf image/deploy definition
app/.helm/           # Kubernetes manifests (deployment/service/ingress/configmap)
taskfile.yaml        # deployment runbook encoded as tasks
.tools-version       # pinned CLI/runtime versions
```

## Toolchain Baseline
From [`.tools-version`](.tools-version):
- Terraform `1.13.5`, TFLint `0.60.0`
- Azure CLI `2.79.0`, Kubelogin `0.2.12`
- Task `3.46.0`, Werf `2.51.6`, Node.js `24.11.1`

## Terraform Runtime Model
Core files:
- [`terraform/terraform.tf`](terraform/terraform.tf): Terraform/provider constraints (`azurerm`, `azuread`, `azapi`).
- [`terraform/backend.tf`](terraform/backend.tf): remote state in Azure Blob with Azure AD auth.
- [`terraform/providers.tf`](terraform/providers.tf): provider initialization and subscription binding.
- [`terraform/locals.tf`](terraform/locals.tf): naming suffixes, env maps, AKS/node-pool parameters, tags.
- [`terraform/main.tf`](terraform/main.tf): module/resource graph.
- [`terraform/data.tf`](terraform/data.tf): lookup of AAD group `aks-admin`.
- [`terraform/outputs.tf`](terraform/outputs.tf): exported RG/VNet/AKS identifiers.

State and workspace strategy:
- `TF_WORKSPACE` is set by CI/CD to one of `dev|qa|stg|prd`.
- `terraform.workspace` is consumed in locals for naming/tagging and environment-specific config.
- Backend settings: RG `rg-investorflow-terraform-state`, SA `investorflowtfstate`, container `terraform-state`, key `terraform.tfstate`.

Provisioned platform graph:
1. Naming module creates deterministic resource names.
2. Resource group is the environment boundary.
3. VNet module provisions per-env CIDR + AKS subnet.
4. ACR module provisions registry for environment image storage.
5. AKS module provisions cluster, node pools, RBAC, OIDC, web app routing integration, and ACR attachment.

Environment network ranges:
- `dev=10.10.0.0/16`, `qa=10.20.0.0/16`, `stg=10.30.0.0/16`, `prd=10.40.0.0/16`

Validation controls (PR pipeline):
- `terraform fmt -check -recursive`
- `tflint --recursive --config .tflint.hcl`
- `terraform validate`
- `terraform plan -lock=false`

## Application Delivery Configuration
Deployment controller: [`taskfile.yaml`](taskfile.yaml)
1. `az-login`: enforce target subscription context.
2. `acr-login`: authenticate OCI push path to target ACR.
3. `kubeconfig`: fetch AKS credentials + convert to Azure CLI auth via kubelogin.
4. `werf:command-with-repo`: execute environment-aware werf command.
5. `deploy`: compose tasks and run `werf converge`.

Build/deploy descriptors:
- [`app/werf.yaml`](app/werf.yaml): image `react-app`, platform `linux/amd64`.
- [`app/Dockerfile`](app/Dockerfile): multi-stage build (Node build stage, unprivileged NGINX runtime).
- Helm sources under `app/.helm/templates`: `deployment.yaml`, `service.yaml`, `ingress.yaml`, `configmap.yaml`.
- Base values: `app/.helm/values.yaml`; overlays: `app/.helm/values/{dev,qa,stg,prd}.yaml`.

Runtime release parameters resolved by `task deploy`:
- Release name: `react-app-<environment>`
- Image repo: `acr<project><region><environment>.azurecr.io/<environment>/react-app`
- Ingress class: `webapprouting.kubernetes.azure.com`

## GitHub Actions Pipelines
| Workflow | Trigger | Scope | Technical Behavior |
|---|---|---|---|
| [`terraform_validations.yml`](.github/workflows/terraform_validations.yml) | PR to `main` on `terraform/**` | Matrix `dev,qa,stg,prd` | Azure login, `init`, `fmt`, `tflint`, `validate`, `plan`; cancels stale runs |
| [`terraform_apply.yml`](.github/workflows/terraform_apply.yml) | Manual dispatch | Selected env | Azure login, `init`, `apply -auto-approve`; env-scoped concurrency |
| [`app_validations.yml`](.github/workflows/app_validations.yml) | PR to `main` on `app/**` | App only | Node setup/cache, `npm ci`, build, lint, tests |
| [`app_deploy.yml`](.github/workflows/app_deploy.yml) | Manual dispatch | Selected env | Azure login, install `task`/`werf`/`kubelogin`, execute `task deploy` |

## Promotion Flow
1. Infra PR triggers multi-env Terraform validation and plans.
2. Operator runs Terraform apply for a target environment.
3. App PR triggers build/lint/test validations.
4. Operator runs app deploy for target environment.
5. Same mechanics are reused across `dev -> qa -> stg -> prd`.

## Identity and Permissions
- Required secret: `AZURE_CREDENTIALS` consumed by `azure/login@v2`.
- AAD dependency: group `aks-admin` must exist for AKS admin binding.
- Backend dependency: Terraform state storage resources must exist before first `terraform init`.
- Principal permissions must cover RG, VNet, ACR, AKS, role assignments, and AKS credential retrieval.

## Local Execution Parity
```bash
# Terraform example (dev)
cd terraform
terraform init
TF_WORKSPACE=dev terraform plan -lock=false

# App deployment example (dev)
ENVIRONMENT=dev task deploy
```

## Important Note
This README was generated with help from an AI assistant, I also used AI for assistance while I was working on this challenge.
