<#
.SYNOPSIS  PASS / FAIL / WAIT / TODO / SKIP for every recipe of the GitHub Actions Cookbook lab.
.EXAMPLE   .\scripts\Verify-Lab.ps1
#>
param([string]$Repo)
$ErrorActionPreference = 'Continue'
if (-not $Repo) { $Repo = gh repo view --json nameWithOwner --jq .nameWithOwner }
if (-not $Repo) { throw 'Run from inside the cloned repository or pass -Repo owner/name' }
$owner = $Repo.Split('/')[0]
$rows = New-Object System.Collections.Generic.List[object]
function Add([string]$ch, [string]$recipe, [string]$result, [string]$detail) {
    $rows.Add([pscustomobject]@{ Result = $result; Chapter = $ch; Recipe = $recipe; Detail = $detail })
}
function Api([string]$path) { $o = gh api $path 2>$null; if ($LASTEXITCODE -eq 0 -and $o) { return ($o | ConvertFrom-Json) } }
function RunState([string]$ch, [string]$recipe, [string]$file, [string]$hint = 'run it') {
    $json = gh run list -R $Repo --workflow $file --limit 30 --json conclusion,status,event,createdAt,databaseId 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) { Add $ch $recipe 'TODO' "$file not on GitHub yet (push it)"; return }
    $runs = @($json | ConvertFrom-Json)
    if (-not $runs.Count) { Add $ch $recipe 'TODO' "$hint ($file)"; return }
    $ok = $runs | Where-Object { $_.conclusion -eq 'success' } | Select-Object -First 1
    $last = $runs[0]
    if ($ok) { Add $ch $recipe 'PASS' ("run {0} success ({1})" -f $ok.databaseId, $ok.event) }
    elseif ($last.status -in @('waiting', 'queued', 'in_progress', 'pending', 'requested')) { Add $ch $recipe 'WAIT' "run $($last.databaseId) $($last.status) - approve or wait" }
    else { Add $ch $recipe 'FAIL' "last run $($last.databaseId): $($last.conclusion)  (gh run view $($last.databaseId) --log-failed)" }
}

# Chapter 1
RunState 'Ch1' 'First workflow (events, inputs, expressions)' 'ch1-first-workflow.yml'
RunState 'Ch1' 'Events (issues, comments, schedule)' 'ch1-events.yml'
RunState 'Ch1' 'Marketplace actions' 'ch1-marketplace.yml'
$vars = Api "repos/$Repo/actions/variables"
if ($vars -and ($vars.variables.name -contains 'COOKBOOK_GREETING')) { RunState 'Ch1' 'Secrets and variables' 'ch1-secrets-variables.yml' }
else { Add 'Ch1' 'Secrets and variables' 'TODO' 'run scripts\Setup-Lab.ps1' }
$envs = @((Api "repos/$Repo/environments").environments.name)
if (($envs -contains 'staging') -and ($envs -contains 'production')) { RunState 'Ch1' 'Environments' 'ch1-environments.yml' 'run it and approve production' }
else { Add 'Ch1' 'Environments' 'TODO' 'run scripts\Setup-Lab.ps1' }
# Chapter 2
RunState 'Ch2' 'Linting workflows (actionlint, yamllint)' 'ch2-lint.yml'
RunState 'Ch2' 'Writing messages to the log' 'ch2-logging.yml'
RunState 'Ch2' 'Enable debug logging' 'ch2-debug.yml'
RunState 'Ch2' 'Developing workflows in branches' 'ch2-branches.yml'
Add 'Ch2' 'Run workflows locally (act)' 'INFO' 'optional, on your PC: see README "Run locally"'
# Chapter 3
RunState 'Ch3' 'Docker, TypeScript and composite actions' 'ch3-actions.yml'
# Chapter 4
RunState 'Ch4' 'GitHub-hosted runners (Linux x64/Arm, Windows, macOS)' 'ch4-hosted-runners.yml'
RunState 'Ch4' 'Self-hosted runner in Docker' 'ch4-self-hosted.yml' 'runner\Start-Runner.ps1, then run it'
Add 'Ch4' 'Large runners' 'SKIP' 'paid plans only'
# Chapter 5
$issues = Api "repos/$Repo/issues?state=all&labels=repo-request&per_page=20"
$done = @($issues | Where-Object { $_.labels.name -contains 'approved' })
if ($done.Count) { Add 'Ch5' 'IssueOps (issue form -> /approve)' 'PASS' "issue #$($done[0].number) approved" }
elseif (@($issues).Count) { Add 'Ch5' 'IssueOps (issue form -> /approve)' 'WAIT' "issue #$(@($issues)[0].number) open - comment /approve" }
else { Add 'Ch5' 'IssueOps (issue form -> /approve)' 'TODO' 'New issue > Repository request' }
RunState 'Ch5' 'GitHub CLI + GITHUB_TOKEN' 'ch5-gh-cli.yml'
RunState 'Ch5' 'Environment approvals and checks' 'ch5-approvals.yml' 'run it and approve'
RunState 'Ch5' 'Reusable workflows + composite action' 'ch5-caller.yml'
# Chapter 6
RunState 'Ch6' 'Build and test with a matrix + test report' 'ch6-ci.yml'
RunState 'Ch6' 'Caching' 'ch6-caching.yml'
RunState 'Ch6' 'CodeQL code scanning' 'ch6-codeql.yml'
$rel = Api "repos/$Repo/releases/latest"
if ($rel) {
    $assets = ($rel.assets.name) -join ', '
    Add 'Ch6' 'Versioning + release + package + SBOM' 'PASS' "$($rel.tag_name): $assets"
} else { RunState 'Ch6' 'Versioning + release + package + SBOM' 'ch6-release.yml' }
# Chapter 7
RunState 'Ch7' 'Build and publish a container (GHCR)' 'ch7-container.yml'
RunState 'Ch7' 'OIDC token claims' 'ch7-oidc.yml'
RunState 'Ch7' 'Environment approval checks (deploy)' 'ch7-deploy.yml' 'runs after the container build; approve production'
$dep = @(gh pr list -R $Repo --state all --author 'app/dependabot' --json number,state --jq '.[] | "\(.number) \(.state)"' 2>$null)
if ($dep.Count -and $dep[0]) { Add 'Ch7' 'Dependabot updates + auto-merge' 'PASS' "$($dep.Count) Dependabot PR(s), latest #$($dep[0])" }
else { Add 'Ch7' 'Dependabot updates + auto-merge' 'WAIT' 'Dependabot opens PRs on its weekly schedule (Insights > Dependency graph > Dependabot)' }
foreach ($c in @('Azure AKS', 'AWS ECS', 'Google GKE')) { Add 'Ch7' "Deploy to $c" 'SKIP' 'kept for later (later\README.md)' }

$rows | Format-Table -AutoSize -Wrap | Out-String -Width 220 | Write-Host
$fail = @($rows | Where-Object Result -eq 'FAIL').Count
$todo = @($rows | Where-Object Result -in @('TODO', 'WAIT')).Count
$pass = @($rows | Where-Object Result -eq 'PASS').Count
if ($fail) { Write-Host "$fail recipe(s) FAILED" -ForegroundColor Red } else { Write-Host "No failures - $pass PASS" -ForegroundColor Green }
if ($todo) { Write-Host "$todo recipe(s) still to do / waiting" -ForegroundColor Yellow }
