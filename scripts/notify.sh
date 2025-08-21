#!/bin/bash
# notify.sh - Sends a Slack notification using curl

BUILD_STATUS=$1
JOB_NAME=$2
BUILD_NUMBER=$3
SLACK_URL=$4

case "$BUILD_STATUS" in
  "success")
    COLOR='good'
    MESSAGE="✅ SUCCESS: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  "failure")
    COLOR='danger'
    MESSAGE="❌ FAILED: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  "unstable")
    COLOR='warning'
    MESSAGE="⚠️ UNSTABLE: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  "aborted")
    COLOR='#AAAAAA'
    MESSAGE="🚫 ABORTED: Build #${BUILD_NUMBER} (${JOB_NAME})"
    ;;
  *)
    COLOR='warning'
    MESSAGE="❓ UNKNOWN: Build #${BUILD_NUMBER} (${JOB_NAME}) - Unknown status: ${BUILD_STATUS}"
    ;;
esac

curl -X POST -H 'Content-type: application/json' --data "{'attachments':[{'color':'$COLOR','text':'$MESSAGE'}]}" "$SLACK_URL"
