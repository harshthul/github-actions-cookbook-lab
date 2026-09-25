#!/bin/bash
# Ch4 ephemeral self-hosted runner: registers, runs exactly ONE job, exits; Docker restarts it clean.
#
# Registration (pick one, both via runner/.env which is git-ignored):
#   RUNNER_TOKEN  short-lived registration token (Start-Runner.ps1 fetches it with gh). Fine for a
#                 quick test, but it expires after 1 hour, so restarts after that fail.
#   GH_PAT        fine-grained PAT limited to THIS repository, permission "Administration: Read and
#                 write". The container fetches a fresh registration token on every start
#                 (this is what lets ephemeral runners keep coming back = the auto-scaling recipe).
set -euo pipefail
: "${GITHUB_REPOSITORY:?set GITHUB_REPOSITORY=owner/repo}"
NAME="${RUNNER_NAME:-cookbook-$(hostname)}"
LABELS="${RUNNER_LABELS:-cookbook}"
API="https://api.github.com/repos/${GITHUB_REPOSITORY}/actions/runners"

token() {   # $1 = registration-token | remove-token
  curl -fsSL -X POST -H "Authorization: Bearer ${GH_PAT}" -H "Accept: application/vnd.github+json" \
       -H "X-GitHub-Api-Version: 2022-11-28" "${API}/$1" | jq -r .token
}

if [ -n "${GH_PAT:-}" ]; then
  REG_TOKEN="$(token registration-token)"
elif [ -n "${RUNNER_TOKEN:-}" ]; then
  REG_TOKEN="${RUNNER_TOKEN}"
else
  echo "Set GH_PAT or RUNNER_TOKEN (see runner/README.md)" >&2
  exit 1
fi

cd /home/runner/actions-runner
./config.sh --unattended --ephemeral --replace \
  --url "https://github.com/${GITHUB_REPOSITORY}" \
  --token "${REG_TOKEN}" \
  --name "${NAME}" --labels "${LABELS}" --work _work
unset REG_TOKEN RUNNER_TOKEN

cleanup() {
  # ephemeral runners unregister themselves after a job; this covers "docker stop" while idle
  if [ -n "${GH_PAT:-}" ] && [ -f .runner ]; then
    ./config.sh remove --token "$(token remove-token)" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Run in the background so this script (PID 1) receives docker's SIGTERM and forwards it;
# a foreground child would delay the trap until Docker's 10 s SIGKILL.
./run.sh &
pid=$!
trap 'kill -TERM "$pid" 2>/dev/null; wait "$pid"' TERM INT
wait "$pid"
