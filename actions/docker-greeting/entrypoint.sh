#!/bin/sh
# Ch3 "Creating a Docker container action" + "Adding output parameters and using job summaries"
set -eu
WHO="${1:-World}"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo "Hello ${WHO}!"
echo "::notice title=Docker action::Greeted ${WHO} at ${NOW}"

# Output parameter: read by later steps as steps.<id>.outputs.time
echo "time=${NOW}" >> "${GITHUB_OUTPUT:-/dev/null}"

# Job summary (Markdown shown on the run page)
{
  echo "### Docker container action :whale:"
  echo ""
  echo "| Input | Value |"
  echo "|---|---|"
  echo "| who-to-greet | ${WHO} |"
  echo "| time | ${NOW} |"
  echo "| runner OS (container) | $(uname -s) $(uname -m) |"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
