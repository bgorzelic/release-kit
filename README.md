# release-kit

Reusable release automation for all projects in the gorzelic.net ecosystem.

When you create a GitHub Release on any connected project, this kit handles:

1. **CI gate** — lint, type-check, and test must pass before proceeding
2. **Version bump** — updates `package.json` (or equivalent) to match the release tag
3. **Project dashboard** — updates the project card on [gorzelic.net/projects](https://gorzelic.net/projects) via webhook
4. **Social media** — posts release announcements to X/Twitter (more platforms coming)

## How It Works

```
┌─────────────────────────┐         ┌──────────────────────────┐
│  Your Repo              │         │  gorzelic.net             │
│                         │         │                          │
│  git push ──────────────┼────────►│  /api/internal/webhook/  │
│                         │ webhook │  github                  │
│  GitHub Release ────────┼────────►│       │                  │
│       │                 │         │       ▼                  │
│       ▼                 │         │  /projects page updates  │
│  release.yml            │         │  (commit, version, etc.) │
│   ├─ ci-check           │         └──────────────────────────┘
│   ├─ bump-version       │
│   └─ announce           │         ┌──────────────────────────┐
│       ├─ twitter ───────┼────────►│  X/Twitter               │
│       ├─ linkedin (soon)│         ├──────────────────────────┤
│       └─ bluesky (soon) │         │  LinkedIn (planned)      │
│                         │         ├──────────────────────────┤
└─────────────────────────┘         │  Bluesky (planned)       │
                                    └──────────────────────────┘
```

## Quick Start

### 1. Register your project on gorzelic.net

```bash
curl -X POST https://gorzelic.net/api/internal/projects \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "slug": "my-project",
    "name": "My Project",
    "description": "What it does.",
    "status": "active",
    "tech": ["python", "gcp"],
    "repo": "bgorzelic/my-project"
  }'
```

Or use the interactive script:

```bash
./scripts/onboard-project.sh
```

### 2. Pick a workflow template for your stack

| Stack | Template | CI Gates |
|-------|----------|----------|
| Node.js / TypeScript | [`workflows/release-node.yml`](workflows/release-node.yml) | eslint + tsc + vitest/jest |
| Python | [`workflows/release-python.yml`](workflows/release-python.yml) | ruff + mypy + pytest |
| Go | [`workflows/release-go.yml`](workflows/release-go.yml) | golangci-lint + go test |
| Terraform / IaC | [`workflows/release-terraform.yml`](workflows/release-terraform.yml) | fmt + validate + tflint |
| Any (no CI) | [`workflows/release-minimal.yml`](workflows/release-minimal.yml) | None — just announce |

### 3. Copy into your repo

```bash
mkdir -p .github/workflows
cp workflows/release-node.yml .github/workflows/release.yml
```

Edit the `# <<< CUSTOMIZE` markers for your project.

### 4. Add the GitHub webhook

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

### 5. Set secrets

If not using org-level secrets:

```bash
gh secret set TWITTER_API_KEY --body "..."
gh secret set TWITTER_API_SECRET --body "..."
gh secret set TWITTER_ACCESS_TOKEN --body "..."
gh secret set TWITTER_ACCESS_SECRET --body "..."
```

### 6. Create a release

```bash
gh release create v1.0.0 --title "v1.0.0" --notes "First release"
```

The workflow will: verify CI → bump version → post to X → update project card.

## Documentation

| Document | Description |
|----------|-------------|
| [docs/ONBOARDING.md](docs/ONBOARDING.md) | Full step-by-step onboarding guide |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | How the system works end-to-end |
| [docs/CUSTOMIZATION.md](docs/CUSTOMIZATION.md) | Adapting workflows for your stack |
| [docs/SOCIAL_PLATFORMS.md](docs/SOCIAL_PLATFORMS.md) | Social media integration guide and roadmap |
| [docs/API_REFERENCE.md](docs/API_REFERENCE.md) | gorzelic.net internal API reference |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Common issues and solutions |

## Secrets Reference

| Secret | Required | Scope | Purpose |
|--------|----------|-------|---------|
| `ADMIN_SECRET` | For onboarding | Local/CI | gorzelic.net API auth |
| `GITHUB_WEBHOOK_SECRET` | Yes | Org or repo | Webhook HMAC verification |
| `TWITTER_API_KEY` | For X posts | Org or repo | OAuth 1.0a consumer key |
| `TWITTER_API_SECRET` | For X posts | Org or repo | OAuth 1.0a consumer secret |
| `TWITTER_ACCESS_TOKEN` | For X posts | Org or repo | OAuth 1.0a access token |
| `TWITTER_ACCESS_SECRET` | For X posts | Org or repo | OAuth 1.0a access secret |

> **Recommendation**: Set Twitter secrets as GitHub **organization secrets** so all repos inherit them automatically.

## Social Media Roadmap

- [x] **X/Twitter** — OAuth 1.0a, posts on non-prerelease
- [ ] **LinkedIn** — OAuth 2.0, company page posts
- [ ] **Bluesky** — AT Protocol, personal feed posts
- [ ] **Discord** — Webhook, channel announcements
- [ ] **Mastodon** — OAuth 2.0, status posts

Each platform is added as an independent job in the workflow. Platforms are **opt-in** — if the secrets aren't configured, the job skips gracefully.

## License

MIT
