# GitHub Actions Cookbook Lab

Hands-on implementation of the recipes in *GitHub Actions Cookbook* (Michael Kaufmann, Packt, 2024): workflows, custom actions, runners, IssueOps, CI, releases, SBOMs, containers and OIDC. Everything is set up to run **free** on a public repository. The cloud deployments (Azure, AWS, GCP) are written but kept in `later/`, switched off.

| Ch | Recipe | Where | Runs |
|---|---|---|---|
| 1 | First workflow: events, inputs, contexts, expressions | `ch1-first-workflow.yml` | manual / push |
| 1 | Events: issues, comments, schedule | `ch1-events.yml` | events |
| 1 | Marketplace actions (checkout, setup-node, github-script, artifacts) | `ch1-marketplace.yml` | manual |
| 1 | Secrets and variables, masking | `ch1-secrets-variables.yml` | manual |
| 1 | Environments (variables per environment, deployment URLs) | `ch1-environments.yml` | manual + approval |
| 2 | Linting workflows (actionlint + shellcheck, yamllint) | `ch2-lint.yml`, `.yamllint.yml` | push / PR |
| 2 | Writing messages to the log (annotations, groups, env files, summary) | `ch2-logging.yml` | manual |
| 2 | Debug logging | `ch2-debug.yml` | manual |
| 2 | Developing workflows in branches | `ch2-branches.yml` | push to branches |
| 2 | Run workflows locally | `.actrc` + [act](https://github.com/nektos/act) | your PC |
| 3 | Docker container action (inputs, outputs, job summary) | `actions/docker-greeting` | via `ch3-actions.yml` |
| 3 | TypeScript action (bundled with ncc, unit tests, dist check) | `actions/ts-greeting` | via `ch3-actions.yml` |
| 3 | Composite action | `actions/composite-node` | via `ch3-actions.yml`, `ch5-reusable.yml` |
| 4 | GitHub-hosted runners: Linux x64 + Arm, Windows, macOS | `ch4-hosted-runners.yml` | manual |
| 4 | Self-hosted ephemeral runners in Docker, scale out, ARC notes | `runner/`, `ch4-self-hosted.yml` | manual |
| 5 | Issue template (issue form) | `.github/ISSUE_TEMPLATE/repo-request.yml` | New issue |
| 5 | IssueOps: validate, plan comment, `/approve`, create repo | `ch5-issue-ops.yml` | issues / comments |
| 5 | GitHub CLI + `GITHUB_TOKEN` with least privilege | `ch5-gh-cli.yml` | manual / weekly |
| 5 | Environment approvals and checks (reviewer, wait timer, branch policy) | `ch5-approvals.yml` | manual + approval |
| 5 | Reusable workflow + caller | `ch5-reusable.yml`, `ch5-caller.yml` | manual |
| 6 | Build and test with a matrix, test report | `ch6-ci.yml`, `src/` | push / PR |
| 6 | Caching | `ch6-caching.yml` | manual |
| 6 | CodeQL (JavaScript/TypeScript + the workflows themselves) | `ch6-codeql.yml` | push / PR / weekly |
| 6 | Versioning, release, GitHub Packages, SBOM, attestations | `ch6-release.yml` | manual |
| 7 | Container to GHCR (multi-arch, SBOM, provenance) | `ch7-container.yml`, `app/` | push / manual |
| 7 | OIDC: see the token claims a cloud would trust | `ch7-oidc.yml` | manual |
| 7 | Environment approval checks: staging then production deploy | `ch7-deploy.yml` | after container build |
| 7 | Dependabot updates + auto-merge | `.github/dependabot.yml`, `ch7-dependabot-automerge.yml` | weekly |
| 7 | **Later:** deploy to Azure AKS, AWS ECS, Google GKE | `later/` | off |

`scripts/Verify-Lab.ps1` prints PASS / FAIL / WAIT / TODO / SKIP for each row.

## Quick start (Windows PowerShell + GitHub CLI)

```powershell
gh auth status                                   # winget install GitHub.cli ; gh auth login
cd E:\github-actions-cookbook
git init -b main ; git add . ; git commit -m "GitHub Actions Cookbook lab"
gh repo create github-actions-cookbook-lab --public --source . --remote origin --push
.\scripts\Setup-Lab.ps1                          # labels, variables, secret, environments, ruleset, settings
.\scripts\Run-Recipes.ps1                        # start the manual recipes (or -Chapter 3)
.\scripts\Verify-Lab.ps1
```

Runs that deploy to `production` or `approval` pause until you approve them: open the run and click *Review deployments*.

### Event-driven recipes

- **IssueOps (Ch5):** *Issues > New issue > Repository request*, then fill in the form. The workflow comments a plan; comment `/approve` as the owner. Without the secret `REPO_ADMIN_TOKEN` this is a dry run, because `GITHUB_TOKEN` cannot create repositories. To really create repos, add a fine-grained PAT with *Administration: Read and write* as `REPO_ADMIN_TOKEN`.
- **Dependabot (Ch7):** it opens update PRs on its weekly schedule. Patch and minor updates auto-merge once the required CodeQL check passes. That check comes from the `main-checks` ruleset Setup-Lab creates, which you bypass as admin, so you can still push to main directly. Updates to `actions/ts-greeting` and major versions wait for you, because `dist/` must be rebuilt. A merge made with `GITHUB_TOKEN` doesn't start `push` workflows on main, so run `ch6-ci`/`ch7-container` by hand afterwards if you want fresh builds.
- **Branches (Ch2):** `git switch -c feature/try ; git push -u origin feature/try`.

### Self-hosted runner (Ch4)

```powershell
cd runner ; .\Start-Runner.ps1 ; gh workflow run ch4-self-hosted.yml ; .\Start-Runner.ps1 -Stop
```

See [runner/README.md](runner/README.md) for scaling out and the security notes.

### Run locally (Ch2)

With Docker Desktop running: `winget install nektos.act`, then `act workflow_dispatch -W .github/workflows/ch2-logging.yml`. Recipes that call the GitHub API need `-s GITHUB_TOKEN="$(gh auth token)"`.

### Working on the TypeScript action

```powershell
cd actions\ts-greeting ; npm ci ; npm test ; npm run build   # commit dist/ - CI fails if it is stale
```

## Cost

Standard GitHub-hosted runners (including macOS and Arm), GHCR, GitHub Packages, CodeQL, Dependabot, environments and attestations are free for **public** repositories. Private repositories use your plan's included minutes and storage. `later/` is the only part that needs paid cloud accounts.

## Security

- Every workflow declares least-privilege `permissions:`, and the default `GITHUB_TOKEN` is read-only (Setup-Lab sets this).
- Untrusted text such as issue titles and comments is passed through `env:`, never pasted into `run:` scripts.
- The self-hosted runner only takes the manually triggered `ch4-self-hosted.yml`, and fork PRs need approval.
- Cloud logins use OIDC, so no cloud keys are stored in GitHub.

## Disclaimer

Not affiliated with GitHub or Packt. The book is copyrighted and not included. This repository is an independent implementation of its recipes; the author's own examples are linked from the [companion repository](https://github.com/PacktPublishing/GitHub-Actions-Cookbook).

## License

[MIT](LICENSE)
