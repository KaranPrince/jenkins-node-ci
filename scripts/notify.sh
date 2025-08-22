#!/bin/bash
set -euo pipefail

BUILD_STATUS=${1:-unknown}
JOB_NAME=${2:-unknown}
BUILD_NUMBER=${3:-0}
SLACK_URL=${4:-}

case "$BUILD_STATUS" in
  success)  COLOR='good';    MESSAGE="✅ SUCCESS: Build #${BUILD_NUMBER} (${JOB_NAME})" ;;
  failure)  COLOR='danger';  MESSAGE="❌ FAILED: Build #${BUILD_NUMBER} (${JOB_NAME})" ;;
  unstable) COLOR='warning'; MESSAGE="⚠️ UNSTABLE: Build #${BUILD_NUMBER} (${JOB_NAME})" ;;
  aborted)  COLOR='#AAAAAA'; MESSAGE="🚫 ABORTED: Build #${BUILD_NUMBER} (${JOB_NAME})" ;;
  *)        COLOR='warning'; MESSAGE="❓ UNKNOWN: Build #${BUILD_NUMBER} (${JOB_NAME}) - Status: ${BUILD_STATUS}" ;;
esac

curl -sS -X POST -H "Content-type: application/json" \
  --data "{\"attachments\":[{\"color\":\"${COLOR}\",\"text\":\"${MESSAGE}\"}]}" \
  "$SLACK_URL" >/dev/null
