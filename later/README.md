# Cloud recipes: kept for later

These Chapter 7 recipes deploy the `cookbook-app` image from GHCR to a cloud. They are **switched off**: GitHub only runs workflows in `.github/workflows/`. They also use `workflow_dispatch` only, so nothing runs by accident once you copy them there.

| File | Cloud | Log-in method (no stored secrets) |
|---|---|---|
| `workflows/ch7-azure-aks.yml` | Azure Kubernetes Service | Entra ID app + federated credential |
| `workflows/ch7-aws-ecs.yml` | AWS Elastic Container Service | IAM OIDC provider + role |
| `workflows/ch7-gcp-gke.yml` | Google Kubernetes Engine | Workload Identity Federation |
| `k8s/deployment.yml` | AKS / GKE | Deployment + LoadBalancer Service |

Run `Ch7 · OIDC token claims` first. It shows the exact `sub` claim each cloud must trust, for example `repo:<owner>/github-actions-cookbook-lab:environment:production`.

## To enable one

1. Create the cloud resources (outline below), then set the listed values as **repository variables**. They are IDs, not secrets.
2. `Copy-Item later\workflows\ch7-azure-aks.yml .github\workflows\`, then commit and push.
3. `gh workflow run ch7-azure-aks.yml`. It waits for your approval on `production`.

### Azure (AKS)

```powershell
az ad app create --display-name gha-cookbook          # note appId -> AZURE_CLIENT_ID
az ad sp create --id <appId>
az ad app federated-credential create --id <appId> --parameters '{"name":"gha-prod","issuer":"https://token.actions.githubusercontent.com","subject":"repo:<owner>/<repo>:environment:production","audiences":["api://AzureADTokenExchange"]}'
az role assignment create --assignee <appId> --role "Azure Kubernetes Service Cluster User Role" --scope <aks-resource-id>
```

Variables: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`, `AKS_RESOURCE_GROUP`, `AKS_CLUSTER`. Kubernetes RBAC on the cluster must also allow `kubectl apply`.

### AWS (ECS)

Create an IAM OIDC identity provider for `token.actions.githubusercontent.com` (audience `sts.amazonaws.com`), then a role whose trust policy limits `token.actions.githubusercontent.com:sub` to `repo:<owner>/<repo>:environment:production`, with ECS deploy permissions. The ECS task definition's container must be named `cookbook-app`.

Variables: `AWS_ROLE_ARN`, `AWS_REGION`, `ECS_CLUSTER`, `ECS_SERVICE`, `ECS_TASK_FAMILY`.

### Google Cloud (GKE)

```bash
gcloud iam workload-identity-pools create github --location=global
gcloud iam workload-identity-pools providers create-oidc github --location=global --workload-identity-pool=github \
  --issuer-uri=https://token.actions.githubusercontent.com \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --attribute-condition="assertion.repository=='<owner>/<repo>'"
gcloud iam service-accounts add-iam-policy-binding <sa>@<project>.iam.gserviceaccount.com --role=roles/iam.workloadIdentityUser \
  --member="principalSet://iam.googleapis.com/projects/<number>/locations/global/workloadIdentityPools/github/attribute.repository/<owner>/<repo>"
```

Variables: `GCP_WIF_PROVIDER` (full provider resource name), `GCP_SERVICE_ACCOUNT`, `GKE_CLUSTER`, `GKE_LOCATION`. The service account needs `roles/container.developer`.

**Cost:** these clouds bill for clusters and load balancers. Delete the resources when you're done.
