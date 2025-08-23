#!/bin/bash
# notify.sh - Sends a Slack notification using curl
# Usage: notify.sh <success|failure|unstable|aborted> <JOB_NAME> <BUILD_NUMBER> <SLACK_URL>

set -euo pipefail

BUILD_STATUS=${1:-unknown}
JOB_NAME=${2:-unknown-job}
BUILD_NUMBER=${3:-0}
SLACK_URL=${4:-}

if [[ -z "${SLACK_URL}" ]]; then
  echo "SLACK_URL is required" >&2
  exit 1
fi

case "$BUILD_STATUS" in
  success)
    COLOR='good'
    MESSAGE="✅ SUCCESS: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  failure)
    COLOR='danger'
    MESSAGE="❌ FAILED: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  unstable)
    COLOR='warning'
    MESSAGE="⚠️ UNSTABLE: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  aborted)
    COLOR='#AAAAAA'
    MESSAGE="🚫 ABORTED: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  *)
    COLOR='warning'
    MESSAGE="❓ UNKNOWN: Build #${BUILD_NUMBER} (${JOB_NAME}) - Unknown status: ${BUILD_STATUS}"
    ;;
esac

# Slack expects proper JSON with double quotes
payload=$(cat <<JSON
{"attachments":[{"color":"${COLOR}","text":"${MESSAGE}"}]}
JSON
)

curl -sS -X POST -H "Content-type: application/json" --data "$payload" "$SLACK_URL" >/dev/null
