# Self-hosted runner in Docker (Chapter 4)

Ephemeral runners: each container registers, runs **one** job, exits, and Docker starts a fresh one. No leftovers between jobs.

```powershell
cd runner
.\Start-Runner.ps1                  # 1 runner, registration token from gh (valid 1 hour)
gh workflow run ch4-self-hosted.yml # the job runs on your PC
.\Start-Runner.ps1 -Count 3 -UsePat # scale out to 3 runners that keep re-registering
.\Start-Runner.ps1 -Stop
```

`-UsePat` asks for a **fine-grained** personal access token limited to this one repository, with *Administration: Read and write*. It is written only to `runner\.env` (git-ignored).

## Security

- Only `ch4-self-hosted.yml` targets these runners, and it only has a **manual** trigger. On a public repository, never point `pull_request` workflows at a self-hosted runner: a fork could run any code on your PC.
- Also set *Settings > Actions > General > Fork pull request workflows* to **Require approval for all external contributors**.
- The containers don't mount `docker.sock`, so jobs can't start containers on your PC.

## Kubernetes (optional): Actions Runner Controller

The book's ARC recipe works on the Kubernetes built into Docker Desktop (*Settings > Kubernetes > Enable*):

```powershell
helm install arc --namespace arc-systems --create-namespace oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
helm install cookbook-arc --namespace arc-runners --create-namespace `
  --set githubConfigUrl="https://github.com/<owner>/<repo>" `
  --set githubConfigSecret.github_token="<fine-grained PAT>" `
  --set minRunners=0 --set maxRunners=3 `
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

Workflows then use `runs-on: cookbook-arc`, the name of the scale set. Remove it with `helm uninstall cookbook-arc -n arc-runners` and `helm uninstall arc -n arc-systems`.
