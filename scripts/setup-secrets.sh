#!/usr/bin/env bash
set -euo pipefail

# Helper to set Twitter secrets on a GitHub repo or organization.
#
# Usage:
#   ./scripts/setup-secrets.sh                  # Interactive
#   ./scripts/setup-secrets.sh --org bgorzelic  # Set org-level secrets

log() { echo -e "\033[1m$*\033[0m"; }
ok()  { echo -e "\033[0;32m$*\033[0m"; }
err() { echo -e "\033[0;31m$*\033[0m" >&2; }

if ! command -v gh &>/dev/null; then
  err "Error: gh CLI is required. Install: brew install gh"
  exit 1
fi

# Parse args
ORG=""
REPO=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --org) ORG="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    *) echo "Usage: $0 [--org ORG_NAME] [--repo OWNER/REPO]"; exit 1 ;;
  esac
done

if [[ -n "$ORG" ]]; then
  log "Setting Twitter secrets for organization: $ORG"
  TARGET_FLAG="--org $ORG"
  TARGET_DESC="org $ORG"
elif [[ -n "$REPO" ]]; then
  log "Setting Twitter secrets for repo: $REPO"
  TARGET_FLAG="-R $REPO"
  TARGET_DESC="repo $REPO"
else
  echo "Choose where to set secrets:"
  echo "  1) Organization (recommended — all repos inherit)"
  echo "  2) Single repository"
  read -rp "Choice [1/2]: " CHOICE

  if [[ "$CHOICE" == "1" ]]; then
    read -rp "Organization name: " ORG
    TARGET_FLAG="--org $ORG"
    TARGET_DESC="org $ORG"
  else
    read -rp "Repository (owner/repo): " REPO
    TARGET_FLAG="-R $REPO"
    TARGET_DESC="repo $REPO"
  fi
fi

echo ""
log "Enter your Twitter/X API credentials:"
echo "(Values are not echoed for security)"
echo ""

read -rsp "TWITTER_API_KEY: " TWITTER_API_KEY
echo ""
read -rsp "TWITTER_API_SECRET: " TWITTER_API_SECRET
echo ""
read -rsp "TWITTER_ACCESS_TOKEN: " TWITTER_ACCESS_TOKEN
echo ""
read -rsp "TWITTER_ACCESS_SECRET: " TWITTER_ACCESS_SECRET
echo ""

echo ""
log "Setting secrets on ${TARGET_DESC}..."

# shellcheck disable=SC2086
gh secret set TWITTER_API_KEY $TARGET_FLAG --body "$TWITTER_API_KEY"
ok "  TWITTER_API_KEY set"

# shellcheck disable=SC2086
gh secret set TWITTER_API_SECRET $TARGET_FLAG --body "$TWITTER_API_SECRET"
ok "  TWITTER_API_SECRET set"

# shellcheck disable=SC2086
gh secret set TWITTER_ACCESS_TOKEN $TARGET_FLAG --body "$TWITTER_ACCESS_TOKEN"
ok "  TWITTER_ACCESS_TOKEN set"

# shellcheck disable=SC2086
gh secret set TWITTER_ACCESS_SECRET $TARGET_FLAG --body "$TWITTER_ACCESS_SECRET"
ok "  TWITTER_ACCESS_SECRET set"

echo ""
ok "All Twitter secrets configured for ${TARGET_DESC}."
echo ""
echo "Repos using the release-kit workflow will now post to X on releases."
