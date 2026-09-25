<#
.SYNOPSIS  One-time repository setup for the GitHub Actions Cookbook lab (run after the first push).
.DESCRIPTION
  Creates, with the GitHub CLI:
    - labels for IssueOps / triage (Ch5)
    - repository variable COOKBOOK_GREETING and secret COOKBOOK_SECRET (Ch1)
    - environments: staging, production (you = required reviewer), approval (reviewer + wait timer
      + only the main branch) with per-environment variable ENV_LABEL (Ch1, Ch5, Ch7)
    - settings: allow auto-merge, Actions may approve PRs (Dependabot auto-merge, Ch7),
      fork PRs need approval, Dependabot security updates
    - ruleset 'main-checks': PRs into main need the CodeQL check (admins bypass), so Dependabot
      auto-merge waits for CI
  Safe to re-run.
.EXAMPLE   .\scripts\Setup-Lab.ps1
#>
param([string]$Repo)
$ErrorActionPreference = 'Stop'
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'GitHub CLI (gh) not found: winget install GitHub.cli' }
if (-not $Repo) { $Repo = gh repo view --json nameWithOwner --jq .nameWithOwner }
if (-not $Repo) { throw 'Run from inside the cloned repository or pass -Repo owner/name' }
function Step($t) { Write-Host "`n== $t" -ForegroundColor Cyan }
function Ok($t)   { Write-Host "  [ok]      $t" -ForegroundColor Green }
function Invoke-GhApi {   # gh with JSON body from a hashtable; returns parsed JSON
    param([string]$Method, [string]$Path, [hashtable]$Body)
    if ($Body) {
        $tmp = New-TemporaryFile
        $Body | ConvertTo-Json -Depth 6 -Compress | Set-Content -Path $tmp -Encoding ascii
        $out = gh api -X $Method $Path --input $tmp.FullName
        Remove-Item $tmp
    } else { $out = gh api -X $Method $Path }
    if ($LASTEXITCODE -ne 0) { throw "gh api $Method $Path failed" }
    if ($out) { return ($out | ConvertFrom-Json) }
}

$me = gh api user | ConvertFrom-Json
Write-Host "Repository: $Repo   you: $($me.login) (id $($me.id))"

Step 'Labels (Ch5 IssueOps, triage)'
$labels = @(
    @('repo-request', '0E8A16', 'IssueOps: request a new repository'),
    @('needs-changes', 'D93F0B', 'IssueOps: request is invalid'),
    @('ready', '1D76DB', 'IssueOps: waiting for /approve'),
    @('approved', '5319E7', 'IssueOps: approved and done'),
    @('triage', 'FBCA04', 'Needs a first look')
)
function Check([string]$what) { if ($LASTEXITCODE -ne 0) { throw "failed: $what" }; Ok $what }
foreach ($l in $labels) { gh label create $l[0] --color $l[1] --description $l[2] --force -R $Repo | Out-Null; Check "label $($l[0])" }

Step 'Variables and secrets (Ch1)'
gh variable set COOKBOOK_GREETING --body 'Hello from a repository variable' -R $Repo | Out-Null; Check 'variable COOKBOOK_GREETING'
$existing = gh secret list -R $Repo --json name --jq '.[].name'
if ($existing -notcontains 'COOKBOOK_SECRET') {
    $value = -join ((48..57) + (97..122) | Get-Random -Count 24 | ForEach-Object { [char]$_ })
    $value | gh secret set COOKBOOK_SECRET -R $Repo | Out-Null
    Check 'secret COOKBOOK_SECRET (random value - it only demonstrates masking)'
} else { Ok 'secret COOKBOOK_SECRET exists' }

Step 'Environments (Ch1 environments, Ch5 approvals, Ch7 deploy)'
$reviewer = @(@{ type = 'User'; id = [int64]$me.id })
Invoke-GhApi PUT "repos/$Repo/environments/staging" @{} | Out-Null
gh variable set ENV_LABEL --env staging --body 'Staging' -R $Repo | Out-Null
Check 'staging (no protection, ENV_LABEL=Staging)'
Invoke-GhApi PUT "repos/$Repo/environments/production" @{ reviewers = $reviewer; prevent_self_review = $false } | Out-Null
gh variable set ENV_LABEL --env production --body 'Production' -R $Repo | Out-Null
Check "production (required reviewer: $($me.login), ENV_LABEL=Production)"
Invoke-GhApi PUT "repos/$Repo/environments/approval" @{
    reviewers = $reviewer; prevent_self_review = $false; wait_timer = 1
    deployment_branch_policy = @{ protected_branches = $false; custom_branch_policies = $true }
} | Out-Null
$policies = (Invoke-GhApi GET "repos/$Repo/environments/approval/deployment-branch-policies").branch_policies
if (-not ($policies | Where-Object { $_.name -eq 'main' })) {
    Invoke-GhApi POST "repos/$Repo/environments/approval/deployment-branch-policies" @{ name = 'main'; type = 'branch' } | Out-Null
}
Ok 'approval (reviewer + 1-minute wait timer + main branch only)'

Step 'Ruleset: main needs a green check (makes Dependabot auto-merge wait for CI)'
$rulesets = @(Invoke-GhApi GET "repos/$Repo/rulesets")
if (-not ($rulesets | Where-Object { $_.name -eq 'main-checks' })) {
    Invoke-GhApi POST "repos/$Repo/rulesets" @{
        name = 'main-checks'; target = 'branch'; enforcement = 'active'
        conditions = @{ ref_name = @{ include = @('~DEFAULT_BRANCH'); exclude = @() } }
        bypass_actors = @(@{ actor_id = 5; actor_type = 'RepositoryRole'; bypass_mode = 'always' })   # 5 = Admin: you can still push to main
        rules = @(@{ type = 'required_status_checks'; parameters = @{
            strict_required_status_checks_policy = $false
            required_status_checks = @(@{ context = 'Analyze (javascript-typescript)' }) } })
    } | Out-Null
    Ok "ruleset 'main-checks': PRs into main need 'Analyze (javascript-typescript)' (admins bypass)"
} else { Ok "ruleset 'main-checks' exists" }

Step 'Repository settings'
gh repo edit $Repo --enable-auto-merge --delete-branch-on-merge | Out-Null; Check 'allow auto-merge, delete branch on merge'
Invoke-GhApi PUT "repos/$Repo/actions/permissions/workflow" @{ default_workflow_permissions = 'read'; can_approve_pull_request_reviews = $true } | Out-Null
Ok 'GITHUB_TOKEN default = read-only; Actions may approve PRs (Dependabot auto-merge)'
try {
    Invoke-GhApi PUT "repos/$Repo/actions/permissions/fork-pr-contributor-approval" @{ approval_policy = 'all_external_contributors' } | Out-Null
    Ok 'fork pull requests from all external contributors need approval'
} catch { Write-Host '  [warn]    could not set fork PR approval - set it in Settings > Actions > General' -ForegroundColor Yellow }
gh api -X PUT "repos/$Repo/vulnerability-alerts" 2>$null | Out-Null; $a = $LASTEXITCODE
gh api -X PUT "repos/$Repo/automated-security-fixes" 2>$null | Out-Null; $b = $LASTEXITCODE
if ($a -eq 0 -and $b -eq 0) { Ok 'Dependabot alerts + security updates' }
else { Write-Host '  [warn]    could not enable Dependabot alerts/security updates - Settings > Code security' -ForegroundColor Yellow }

Write-Host "`nDone. Next: .\scripts\Run-Recipes.ps1   then   .\scripts\Verify-Lab.ps1" -ForegroundColor Green
