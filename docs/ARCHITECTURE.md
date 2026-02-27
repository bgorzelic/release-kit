# Architecture

> How the release-kit ecosystem works end-to-end.

## System Overview

The release-kit connects three systems:

1. **Your GitHub repos** — source code + release events
2. **gorzelic.net** — project dashboard + webhook receiver + internal API
3. **Social media platforms** — release announcements

```
┌──────────────┐     webhook      ┌──────────────────┐
│  GitHub Repo │ ───────────────► │  gorzelic.net     │
│              │  push / release  │                   │
│              │                  │  Webhook receiver  │
│              │                  │  (/api/internal/   │
│              │                  │   webhook/github)  │
│              │                  │       │            │
│  release.yml │                  │       ▼            │
│  (Actions)   │                  │  Upstash Redis KV  │
│   │          │                  │       │            │
│   ├─ ci-check│                  │       ▼            │
│   ├─ bump    │                  │  /projects page    │
│   └─ announce│                  │  (SSR from KV)     │
│       │      │                  └──────────────────┘
│       ▼      │
│  Twitter API │
│  LinkedIn API│ (planned)
│  Bluesky API │ (planned)
└──────────────┘
```

## Data Flow

### On `git push`

1. Developer pushes code to GitHub
2. GitHub sends a `push` webhook event to `https://gorzelic.net/api/internal/webhook/github`
3. gorzelic.net verifies the HMAC-SHA256 signature
4. Looks up the project by matching `repository.full_name` against registered projects
5. Updates: `lastCommitMessage`, `lastCommitAuthor`, `lastCommit`, `lastActivity`
6. Stores updated project in Upstash Redis KV
7. Next visit to `/projects` renders the updated card

### On GitHub Release

1. Developer creates a GitHub Release (tag `vX.Y.Z`)
2. **Webhook path**: GitHub sends a `release` event → gorzelic.net updates `version` + `lastActivity`
3. **Workflow path**: `release.yml` runs in the repo:
   - `ci-check`: Runs lint, type-check, tests
   - `bump-version`: Updates package.json/pyproject.toml and commits
   - `announce-twitter`: Composes and posts a tweet via OAuth 1.0a

Both paths run independently — the webhook updates the dashboard, the workflow handles announcements.

## Authentication

### Webhook Verification

GitHub signs each webhook payload with HMAC-SHA256 using the shared `GITHUB_WEBHOOK_SECRET`. The gorzelic.net webhook endpoint:

1. Computes `HMAC-SHA256(secret, raw_body)`
2. Compares against the `X-Hub-Signature-256` header
3. Uses `timingSafeEqual` to prevent timing attacks

### Internal API

Project CRUD operations (`/api/internal/projects/*`) require a Bearer token:

```
Authorization: Bearer $ADMIN_SECRET
```

The comparison uses `timingSafeEqual` from `node:crypto`.

### Twitter OAuth 1.0a

The tweet posting uses OAuth 1.0a HMAC-SHA1 signing:

1. Constructs OAuth parameter string (consumer key, nonce, timestamp, token)
2. Creates signature base string: `POST&url&params`
3. Signs with `HMAC-SHA1(consumer_secret&token_secret, base_string)`
4. Sends as `Authorization: OAuth ...` header

All credentials are passed via environment variables — never interpolated in shell.

## Storage

### Upstash Redis KV (gorzelic.net)

```
internal:projects:index          → Set of project slugs
internal:projects:{slug}         → JSON project object
```

Project schema:

```typescript
{
  slug: string;            // "my-project"
  name: string;            // "My Project"
  description: string;     // "What it does"
  status: "active" | "paused" | "completed";
  tech: string[];          // ["python", "gcp"]
  repo?: string;           // "bgorzelic/my-project"
  lastCommit?: string;     // Git SHA
  lastCommitMessage?: string; // First line of commit message
  lastCommitAuthor?: string;  // Commit author name
  lastActivity?: string;   // ISO 8601 timestamp
  url?: string;            // Live deployment URL
  version?: string;        // Release tag (e.g. "v1.2.0")
}
```

## Security Considerations

- **No secrets in workflows**: All credentials use `secrets.*` context or `env:` blocks
- **HMAC verification**: Webhooks are authenticated via signature, not just URL obscurity
- **Timing-safe comparisons**: Both webhook HMAC and Bearer token use `timingSafeEqual`
- **Platform opt-in**: Social media jobs skip gracefully when secrets aren't configured
- **No `${{ }}` in `run:` blocks**: Prevents GitHub Actions injection attacks
