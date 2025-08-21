#!/bin/bash
# notify.sh - Sends a Slack notification based on build status

BUILD_STATUS=$1
JOB_NAME=$2
BUILD_NUMBER=$3

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

slackSend(
  channel: '#ci-cd',
  color: "${COLOR}",
  message: "${MESSAGE}"
)
