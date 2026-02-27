# Troubleshooting

> Common issues and how to fix them.

## Webhook Issues

### Project card not updating after push

**Symptom**: You push code but the project card on gorzelic.net doesn't show the new commit.

**Check**:
1. Verify the webhook is delivering: Repo → Settings → Webhooks → Recent Deliveries
2. Look for a green checkmark (200 response)
3. If the response body says `"skipped": "no matching project"`, the `repo` field doesn't match

**Fix**: Ensure the `repo` field matches exactly:
```bash
# Check what's registered
curl -s https://gorzelic.net/api/internal/projects/my-project | jq '.project.repo'

# Should match your GitHub repo's full name (case-sensitive)
# "bgorzelic/my-project" ← NOT "bgorzelic/My-Project"
```

### Webhook returning 401

**Symptom**: GitHub webhook deliveries show 401 responses.

**Check**: The `GITHUB_WEBHOOK_SECRET` must match between:
- The webhook configuration in GitHub (Settings → Webhooks → Secret)
- The `GITHUB_WEBHOOK_SECRET` env var on gorzelic.net (Vercel dashboard)

**Fix**: Re-set the secret in both places. Regenerate if you're unsure.

### Webhook returning 503

**Symptom**: GitHub webhook deliveries show 503 responses.

**Causes**:
- `GITHUB_WEBHOOK_SECRET` env var not set on gorzelic.net → returns "Webhook not configured"
- KV store not configured → returns "KV store not configured"

**Fix**: Check Vercel environment variables for `GITHUB_WEBHOOK_SECRET` and `KV_REST_API_*` vars.

---

## Release Workflow Issues

### Workflow not triggering

**Symptom**: You create a GitHub Release but the workflow doesn't run.

**Check**:
1. The file must be at `.github/workflows/release.yml` on the `main` branch
2. The trigger must match: `on: release: types: [published]`
3. Check Actions → All workflows → filter by "Release"

**Fix**: Ensure the workflow file was pushed to `main` before creating the release.

### CI check failing in release workflow

**Symptom**: The `ci-check` job fails, blocking the version bump and announcement.

**Fix**: Fix the CI issue on `main` first, then create a new release. The release workflow runs CI against `main`.

### Version bump skipped

**Symptom**: The `bump-version` job logs say "Version already at X.Y.Z, skipping"

**This is normal** if:
- You manually bumped the version before releasing
- A previous release workflow already bumped to this version

### Version bump commits but tweet doesn't post

**Symptom**: Version bump succeeds but `announce-twitter` is skipped or fails.

**Check**:
1. Was this a `workflow_dispatch` (manual) run? Twitter only fires on `release` events.
2. Was the release marked as pre-release? Pre-releases are intentionally skipped.
3. Are all 4 Twitter secrets configured? Check the `Check secrets` step output.

---

## Twitter/X Issues

### "Twitter secrets not configured, skipping"

**Fix**: Set all 4 secrets:
```bash
gh secret set TWITTER_API_KEY --body "..."
gh secret set TWITTER_API_SECRET --body "..."
gh secret set TWITTER_ACCESS_TOKEN --body "..."
gh secret set TWITTER_ACCESS_SECRET --body "..."
```

### Twitter API 401 or 403

**Causes**:
- App doesn't have **Read and Write** permissions (Settings → User authentication settings)
- Access token was generated before enabling Write permissions → regenerate it
- App is suspended or in read-only mode

**Fix**: Go to [developer.x.com](https://developer.x.com) → Your app → Settings:
1. Enable Read and Write under User authentication settings
2. Regenerate access token and secret
3. Update GitHub secrets

### Twitter API 429 (Rate Limited)

**Cause**: Too many tweets in a short period.

**Fix**: Wait and retry. Twitter's rate limits for tweet creation are generous (300 per 15 min for v2 API). If you're hitting this, something else is wrong (duplicate workflow runs, etc.).

### Tweet text is empty or truncated

**Check**: The `Compose tweet` step. Ensure the `TWEET_TEXT` output is correctly set using the heredoc pattern:
```yaml
{
  echo "tweet<<EOF"
  echo "$TWEET"
  echo "EOF"
} >> "$GITHUB_OUTPUT"
```

---

## Onboarding Script Issues

### "ADMIN_SECRET env var is required"

**Fix**: Export the secret before running:
```bash
export ADMIN_SECRET="your-token"
./scripts/onboard-project.sh
```

### "Webhook creation failed"

**Causes**:
- `gh` CLI not authenticated → `gh auth login`
- Insufficient permissions on the repo → need admin access
- Webhook already exists for this URL → check existing hooks

**Fix**:
```bash
# Check existing webhooks
gh api repos/bgorzelic/my-project/hooks --jq '.[] | {id, url: .config.url}'

# Delete duplicate if needed
gh api repos/bgorzelic/my-project/hooks/HOOK_ID --method DELETE
```

### Registration returns 400

**Common errors**:
- `"slug is required (lowercase alphanumeric with hyphens)."` → Slug can only contain `a-z`, `0-9`, `-`
- `"tech must be an array of strings."` → Ensure tech is a JSON array, not comma-separated string
- `"status must be \"active\", \"paused\", or \"completed\"."` → Typo in status value

---

## General Debugging

### Check the full webhook payload

```bash
# List recent deliveries
gh api repos/bgorzelic/my-project/hooks/HOOK_ID/deliveries --jq '.[0]'
```

### Check project state

```bash
# Full project data
curl -s https://gorzelic.net/api/internal/projects/my-project | jq

# Just the fields that webhook updates
curl -s https://gorzelic.net/api/internal/projects/my-project | \
  jq '.project | {version, lastCommitMessage, lastCommitAuthor, lastActivity}'
```

### Check workflow run logs

```bash
# List recent workflow runs
gh run list --workflow=release.yml --limit=5

# View a specific run
gh run view RUN_ID --log
```
