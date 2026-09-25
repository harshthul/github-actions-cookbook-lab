<#
.SYNOPSIS  Ch4: start ephemeral self-hosted GitHub Actions runners in Docker Desktop.
.EXAMPLE   .\Start-Runner.ps1                 # 1 runner, registration token via gh (valid 1 h)
.EXAMPLE   .\Start-Runner.ps1 -Count 3 -UsePat  # 3 runners that keep re-registering (fine-grained PAT)
.EXAMPLE   .\Start-Runner.ps1 -Stop
.NOTES     Needs Docker Desktop and the GitHub CLI (gh auth login). Secrets go to runner\.env (git-ignored).
#>
param(
    [string]$Repo,
    [ValidateRange(1, 10)][int]$Count = 1,
    [switch]$UsePat,
    [switch]$Stop
)
$ErrorActionPreference = 'Continue'   # docker/gh write progress to stderr
Set-Location $PSScriptRoot

if (-not $Repo) { $Repo = (gh repo view --json nameWithOwner --jq .nameWithOwner 2>$null) }
if (-not $Repo) { throw 'Could not detect the repository - pass -Repo owner/name' }

if ($Stop) {
    docker compose down
    Write-Host 'Runners stopped. Registered runners now:' -ForegroundColor Green
    gh api "repos/$Repo/actions/runners" --jq '.runners[] | "\(.name)  \(.status)"'
    return
}

docker info *> $null
if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop is not running.' }

$lines = @("GITHUB_REPOSITORY=$Repo")
if ($UsePat) {
    Write-Host "Fine-grained PAT: Resource owner = you, Repository access = only $Repo," -ForegroundColor Cyan
    Write-Host '  Permissions > Repository > Administration: Read and write. Expire it in 30-90 days.' -ForegroundColor Cyan
    $sec = Read-Host 'Paste the PAT (hidden)' -AsSecureString
    $pat = [Runtime.InteropServices.Marshal]::PtrToStringBSTR([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
    if (-not $pat) { throw 'No PAT entered.' }
    $lines += "GH_PAT=$pat"
} else {
    $token = gh api -X POST "repos/$Repo/actions/runners/registration-token" --jq .token
    if (-not $token) { throw "Could not get a registration token. You need admin rights on $Repo (gh auth status)." }
    $lines += "RUNNER_TOKEN=$token"
    Write-Host 'Using a registration token (valid 1 hour). Use -UsePat for runners that survive restarts.' -ForegroundColor Yellow
}
Set-Content -Path .env -Value $lines -Encoding ascii
Remove-Variable pat, token -ErrorAction SilentlyContinue

docker compose up -d --build --scale "runner=$Count"
Write-Host "Waiting for $Count runner(s) to come online..." -ForegroundColor Yellow
$deadline = (Get-Date).AddMinutes(3)
do {
    Start-Sleep 5
    $online = @(gh api "repos/$Repo/actions/runners" --jq '.runners[] | select(.status=="online") | .name' 2>$null).Count
    Write-Host "  online: $online / $Count"
} until ($online -ge $Count -or (Get-Date) -gt $deadline)
Write-Host "Now run:  gh workflow run ch4-self-hosted.yml -R $Repo" -ForegroundColor Green
