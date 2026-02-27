#!/usr/bin/env bash
set -euo pipefail

# Onboard a GitHub repo into the gorzelic.net ecosystem.
# Registers the project and sets up the GitHub webhook.
#
# Usage:
#   export ADMIN_SECRET="your-token"
#   export GITHUB_WEBHOOK_SECRET="your-webhook-secret"
#   ./scripts/onboard-project.sh
#
# Requires: gh CLI, jq, curl

readonly API_BASE="https://gorzelic.net/api/internal"
readonly WEBHOOK_URL="${API_BASE}/webhook/github"

log() { echo -e "\033[1m$*\033[0m"; }
ok()  { echo -e "\033[0;32m$*\033[0m"; }
err() { echo -e "\033[0;31m$*\033[0m" >&2; }

# ── Preflight ─────────────────────────────────────────────────────────
if [[ -z "${ADMIN_SECRET:-}" ]]; then
  err "Error: ADMIN_SECRET env var is required."
  echo "  export ADMIN_SECRET=your-gorzelic-net-api-token"
  exit 1
fi

if [[ -z "${GITHUB_WEBHOOK_SECRET:-}" ]]; then
  err "Error: GITHUB_WEBHOOK_SECRET env var is required."
  echo "  export GITHUB_WEBHOOK_SECRET=your-webhook-secret"
  exit 1
fi

for cmd in gh jq curl; do
  if ! command -v "$cmd" &>/dev/null; then
    err "Error: $cmd is required. Install: brew install $cmd"
    exit 1
  fi
done

# ── Collect project info ──────────────────────────────────────────────
echo ""
log "=== Onboard a project to gorzelic.net ==="
echo ""

read -rp "GitHub repo (owner/name, e.g. bgorzelic/my-project): " REPO
read -rp "Project slug (lowercase-hyphens, e.g. my-project): " SLUG
read -rp "Display name (e.g. My Project): " NAME
read -rp "One-line description: " DESC
read -rp "Tech tags (comma-separated, e.g. python,gcp,terraform): " TECH_RAW
read -rp "Status [active/paused/completed] (default: active): " STATUS
STATUS="${STATUS:-active}"
read -rp "Live URL (optional, press Enter to skip): " URL

# Build tech array
TECH_JSON=$(echo "$TECH_RAW" | tr ',' '\n' | sed 's/^ *//;s/ *$//' | jq -R . | jq -s .)

# Build JSON payload
PROJECT_JSON=$(jq -n \
  --arg slug "$SLUG" \
  --arg name "$NAME" \
  --arg desc "$DESC" \
  --arg status "$STATUS" \
  --argjson tech "$TECH_JSON" \
  --arg repo "$REPO" \
  --arg url "$URL" \
  '{slug: $slug, name: $name, description: $desc, status: $status, tech: $tech, repo: $repo} + (if $url != "" then {url: $url} else {} end)')

echo ""
log "Registering project..."
echo "$PROJECT_JSON" | jq .

# ── Register ──────────────────────────────────────────────────────────
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${API_BASE}/projects" \
  -H "Authorization: Bearer ${ADMIN_SECRET}" \
  -H "Content-Type: application/json" \
  -d "$PROJECT_JSON")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [[ "$HTTP_CODE" == "201" ]]; then
  ok "Project registered successfully."
else
  err "Registration failed (HTTP $HTTP_CODE):"
  echo "$BODY" | jq . 2>/dev/null || echo "$BODY"
  exit 1
fi

# ── Webhook ───────────────────────────────────────────────────────────
echo ""
log "Adding GitHub webhook..."

HOOK_RESPONSE=$(gh api "repos/${REPO}/hooks" \
  --method POST \
  --field name=web \
  --field active=true \
  --field 'events[]=push' \
  --field 'events[]=release' \
  --field "config[url]=${WEBHOOK_URL}" \
  --field 'config[content_type]=json' \
  --field "config[secret]=${GITHUB_WEBHOOK_SECRET}" 2>&1) || {
  err "Webhook creation failed:"
  echo "$HOOK_RESPONSE"
  echo ""
  echo "You may need to add the webhook manually:"
  echo "  URL: ${WEBHOOK_URL}"
  echo "  Content type: application/json"
  echo "  Secret: (your GITHUB_WEBHOOK_SECRET)"
  echo "  Events: push, release"
  exit 1
}

HOOK_ID=$(echo "$HOOK_RESPONSE" | jq -r '.id')
ok "Webhook created (ID: ${HOOK_ID})"

# ── Summary ───────────────────────────────────────────────────────────
echo ""
log "=== Next Steps ==="
echo ""
echo "  1. Copy a release workflow template into your repo:"
echo ""
echo "     Node.js:    cp workflows/release-node.yml .github/workflows/release.yml"
echo "     Python:     cp workflows/release-python.yml .github/workflows/release.yml"
echo "     Go:         cp workflows/release-go.yml .github/workflows/release.yml"
echo "     Terraform:  cp workflows/release-terraform.yml .github/workflows/release.yml"
echo "     Minimal:    cp workflows/release-minimal.yml .github/workflows/release.yml"
echo ""
echo "  2. Edit the # <<< CUSTOMIZE markers in the workflow"
echo ""
echo "  3. Add Twitter secrets (if not using org secrets):"
echo "     gh secret set TWITTER_API_KEY -R ${REPO} --body '...'"
echo "     gh secret set TWITTER_API_SECRET -R ${REPO} --body '...'"
echo "     gh secret set TWITTER_ACCESS_TOKEN -R ${REPO} --body '...'"
echo "     gh secret set TWITTER_ACCESS_SECRET -R ${REPO} --body '...'"
echo ""
echo "  4. Test with: git push && gh release create v0.1.0 --notes 'test'"
echo ""
echo "  5. Verify: curl -s https://gorzelic.net/api/internal/projects/${SLUG} | jq"
echo ""
ok "Done! '${NAME}' is now on gorzelic.net/projects"
