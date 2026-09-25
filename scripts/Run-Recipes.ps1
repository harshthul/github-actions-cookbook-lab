<#
.SYNOPSIS  Start the manual (workflow_dispatch) recipes, chapter by chapter.
.EXAMPLE   .\scripts\Run-Recipes.ps1                 # all free recipes
.EXAMPLE   .\scripts\Run-Recipes.ps1 -Chapter 6
.EXAMPLE   .\scripts\Run-Recipes.ps1 -Chapter 4 -SelfHosted   # needs runner\Start-Runner.ps1 first
.NOTES     Runs that deploy to 'production' or 'approval' wait for you: open the run and click
           "Review deployments" > Approve (or: gh run view <id> --web).
#>
param([int[]]$Chapter = @(1, 2, 3, 4, 5, 6, 7), [switch]$SelfHosted, [string]$Repo)
$ErrorActionPreference = 'Continue'
if (-not $Repo) { $Repo = gh repo view --json nameWithOwner --jq .nameWithOwner }
if (-not $Repo) { throw 'Run from inside the cloned repository or pass -Repo owner/name' }

# chapter, workflow file, extra -f inputs
$plan = @(
    @(1, 'ch1-first-workflow.yml', @('name=Harsh', 'mood=curious')),
    @(1, 'ch1-events.yml', @()),
    @(1, 'ch1-marketplace.yml', @()),
    @(1, 'ch1-secrets-variables.yml', @()),
    @(1, 'ch1-environments.yml', @()),
    @(2, 'ch2-lint.yml', @()),
    @(2, 'ch2-logging.yml', @()),
    @(2, 'ch2-debug.yml', @()),
    @(2, 'ch2-branches.yml', @()),
    @(3, 'ch3-actions.yml', @('who=Harsh')),
    @(4, 'ch4-hosted-runners.yml', @()),
    @(5, 'ch5-gh-cli.yml', @('task=triage')),
    @(5, 'ch5-caller.yml', @()),
    @(5, 'ch5-approvals.yml', @()),
    @(6, 'ch6-ci.yml', @()),
    @(6, 'ch6-caching.yml', @()),
    @(6, 'ch6-codeql.yml', @()),
    @(6, 'ch6-release.yml', @('bump=patch')),
    @(7, 'ch7-container.yml', @()),
    @(7, 'ch7-oidc.yml', @())
)
if ($SelfHosted) { $plan += , @(4, 'ch4-self-hosted.yml', @()) }

foreach ($p in $plan | Where-Object { $Chapter -contains $_[0] }) {
    $args2 = @('workflow', 'run', $p[1], '-R', $Repo)
    foreach ($i in $p[2]) { $args2 += @('-f', $i) }
    & gh @args2 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { Write-Host ("  [started] Ch{0}  {1}" -f $p[0], $p[1]) -ForegroundColor Green }
    else { Write-Host ("  [error]   Ch{0}  {1} (is it pushed to the default branch?)" -f $p[0], $p[1]) -ForegroundColor Red }
    Start-Sleep -Milliseconds 700
}
if ($Chapter -contains 6) { Write-Host "  [info]    run ch6-caching.yml a second time to see cache-hit=true" -ForegroundColor Gray }
Write-Host "`nWatch: gh run list -R $Repo   |   Approve: gh run view <id> --web" -ForegroundColor Cyan
Write-Host "Ch5 IssueOps and Ch7 Dependabot are event-driven - see README." -ForegroundColor Cyan
