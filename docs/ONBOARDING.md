# Project Onboarding Guide

> Step-by-step instructions to connect any repository to the gorzelic.net release ecosystem.

## Prerequisites

Before starting, gather these credentials:

| Credential | Where to find it | What it does |
|-----------|-----------------|-------------|
| `ADMIN_SECRET` | gorzelic.net Vercel env vars / 1Password | Authenticates API calls to register projects |
| `GITHUB_WEBHOOK_SECRET` | Shared across all repos / 1Password | Verifies webhook payloads (HMAC-SHA256) |
| Twitter API keys (4) | GitHub org secrets or per-repo | Posts release announcements to X |

You also need the `gh` CLI authenticated (`gh auth status`).

---

## Step 1: Register the Project

Every project needs a one-time registration on gorzelic.net. This creates the project card on the [/projects](https://gorzelic.net/projects) dashboard.

### Option A: Interactive script

```bash
export ADMIN_SECRET="your-token"
export GITHUB_WEBHOOK_SECRET="your-webhook-secret"
./scripts/onboard-project.sh
```

The script prompts for all details and handles both registration and webhook setup.

### Option B: Manual API call

```bash
curl -X POST https://gorzelic.net/api/internal/projects \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "slug": "my-project",
    "name": "My Project",
    "description": "One-line description of what it does.",
    "status": "active",
    "tech": ["python", "gcp", "terraform"],
    "repo": "bgorzelic/my-project",
    "url": "https://my-project.example.com"
  }'
```

### Project fields

| Field | Required | Type | Description |
|-------|----------|------|-------------|
| `slug` | Yes | `string` | URL-safe ID: lowercase letters, numbers, hyphens only |
| `name` | Yes | `string` | Display name shown on the project card |
| `description` | Yes | `string` | One-line description |
| `status` | Yes | `"active" \| "paused" \| "completed"` | Current project status |
| `tech` | Yes | `string[]` | Technology tags (shown as badges) |
| `repo` | No | `string` | GitHub `owner/repo` — **must match exactly** for webhook to work |
| `url` | No | `string` | Live URL if the project is deployed somewhere |
| `version` | No | `string` | Current version — auto-updated by release webhook events |

### Verify registration

```bash
# All projects
curl -s https://gorzelic.net/api/internal/projects | jq '.projects[].name'

# Single project
curl -s https://gorzelic.net/api/internal/projects/my-project | jq
```

---

## Step 2: Add the GitHub Webhook

The webhook sends push and release events to gorzelic.net, which updates the project card in real time.

### Option A: Via CLI (recommended)

```bash
gh api repos/bgorzelic/my-project/hooks \
  --method POST \
  --field name=web \
  --field active=true \
  --field 'events[]=push' \
  --field 'events[]=release' \
  --field 'config[url]=https://gorzelic.net/api/internal/webhook/github' \
  --field 'config[content_type]=json' \
  --field "config[secret]=$GITHUB_WEBHOOK_SECRET"
```

### Option B: Via GitHub UI

1. Repo → **Settings** → **Webhooks** → **Add webhook**
2. **Payload URL**: `https://gorzelic.net/api/internal/webhook/github`
3. **Content type**: `application/json`
4. **Secret**: Your `GITHUB_WEBHOOK_SECRET` value
5. **Events**: Check **Pushes** and **Releases**
6. Click **Add webhook**

### What the webhook updates

| GitHub Event | Fields Updated on Project Card |
|-------------|-------------------------------|
| `push` | `lastCommitMessage` (first line of commit), `lastCommitAuthor`, `lastCommit` (SHA), `lastActivity` |
| `release` | `version` (tag name), `lastActivity` |

---

## Step 3: Add the Release Workflow

Choose the template matching your project's stack:

| Stack | Template | What it does |
|-------|----------|-------------|
| Node.js / TypeScript | `workflows/release-node.yml` | eslint + tsc + test → npm version bump → tweet |
| Python | `workflows/release-python.yml` | ruff + mypy + pytest → pyproject.toml bump → tweet |
| Go | `workflows/release-go.yml` | golangci-lint + go test → tweet (no version file) |
| Terraform / IaC | `workflows/release-terraform.yml` | fmt + validate → tweet (no version file) |
| Any (announce only) | `workflows/release-minimal.yml` | Just tweet — no CI, no version bump |

### Copy into your repo

```bash
# From the release-kit directory:
mkdir -p /path/to/my-project/.github/workflows
cp workflows/release-node.yml /path/to/my-project/.github/workflows/release.yml

# Or clone and copy:
git clone https://github.com/bgorzelic/release-kit.git /tmp/release-kit
cp /tmp/release-kit/workflows/release-node.yml .github/workflows/release.yml
```

### Customize

Search for `# <<< CUSTOMIZE` markers in the workflow file. Common changes:

- **Node version**: Change `.nvmrc` to a fixed `node-version: '20'`
- **Package manager**: Switch `npm ci` to `pnpm install` or `yarn install`
- **Lint command**: Replace `eslint` with your project's linter
- **Tweet text**: Edit the template string in the announce step
- **Hashtags**: Change `#buildinpublic #opensource` to your project's tags

---

## Step 4: Configure Secrets

### Option A: Organization secrets (recommended)

Set once, all repos inherit:

```bash
# Twitter/X credentials (shared across all repos)
gh secret set TWITTER_API_KEY --org bgorzelic --body "..."
gh secret set TWITTER_API_SECRET --org bgorzelic --body "..."
gh secret set TWITTER_ACCESS_TOKEN --org bgorzelic --body "..."
gh secret set TWITTER_ACCESS_SECRET --org bgorzelic --body "..."
```

### Option B: Per-repo secrets

```bash
gh secret set TWITTER_API_KEY -R bgorzelic/my-project --body "..."
gh secret set TWITTER_API_SECRET -R bgorzelic/my-project --body "..."
gh secret set TWITTER_ACCESS_TOKEN -R bgorzelic/my-project --body "..."
gh secret set TWITTER_ACCESS_SECRET -R bgorzelic/my-project --body "..."
```

---

## Step 5: Test End-to-End

### Test webhook (push event)

```bash
git commit --allow-empty -m "test: verify webhook integration"
git push
```

Check the project card updated:

```bash
curl -s https://gorzelic.net/api/internal/projects/my-project | \
  jq '.project | {lastCommitMessage, lastCommitAuthor, lastActivity}'
```

### Test release workflow

```bash
gh release create v0.1.0 --title "v0.1.0" --notes "Initial release — testing automation"
```

Verify:
- [ ] GitHub Actions release workflow ran successfully
- [ ] Version badge shows `v0.1.0` on [gorzelic.net/projects](https://gorzelic.net/projects)
- [ ] Tweet posted to X (check workflow logs for URL)
- [ ] `package.json` version bumped (check latest commit on `main`)

---

## Managing Projects After Onboarding

### Update project metadata

```bash
curl -X PUT https://gorzelic.net/api/internal/projects/my-project \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"status": "completed", "description": "Updated description"}'
```

### Pause a project

```bash
curl -X PUT https://gorzelic.net/api/internal/projects/my-project \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"status": "paused"}'
```

### Remove a project

```bash
curl -X DELETE https://gorzelic.net/api/internal/projects/my-project \
  -H "Authorization: Bearer $ADMIN_SECRET"
```

Don't forget to also remove the webhook from the repo:

```bash
# List webhooks to find the ID
gh api repos/bgorzelic/my-project/hooks --jq '.[] | {id, config: .config.url}'

# Delete by ID
gh api repos/bgorzelic/my-project/hooks/HOOK_ID --method DELETE
```
