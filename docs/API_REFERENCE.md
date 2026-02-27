# API Reference

> gorzelic.net Internal API for managing projects.

Base URL: `https://gorzelic.net/api/internal`

## Authentication

Protected endpoints require a Bearer token:

```
Authorization: Bearer $ADMIN_SECRET
```

Public endpoints (GET) require no authentication.

---

## Projects

### List All Projects

```
GET /projects
```

**Auth**: None (public)

**Response** `200`:
```json
{
  "projects": [
    {
      "slug": "gorzelic-net",
      "name": "gorzelic.net",
      "description": "AI-native interactive career site",
      "status": "active",
      "tech": ["next.js", "react", "typescript", "tailwind"],
      "repo": "bgorzelic/gorzelic-net",
      "url": "https://gorzelic.net",
      "version": "v2.8.0",
      "lastCommitMessage": "chore: bump version to v2.8.0",
      "lastCommitAuthor": "github-actions[bot]",
      "lastActivity": "2026-02-25T20:00:00.000Z"
    }
  ]
}
```

Projects are sorted: active first, then paused, then completed.

---

### Get Single Project

```
GET /projects/{slug}
```

**Auth**: None (public)

**Response** `200`:
```json
{
  "project": { ... }
}
```

**Response** `404`:
```json
{
  "error": "Not found."
}
```

---

### Create / Register Project

```
POST /projects
```

**Auth**: Required (Bearer token)

**Body** (JSON):

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `slug` | `string` | Yes | URL-safe ID (`^[a-z0-9-]+$`) |
| `name` | `string` | Yes | Display name |
| `description` | `string` | Yes | One-line description |
| `status` | `string` | Yes | `"active"`, `"paused"`, or `"completed"` |
| `tech` | `string[]` | Yes | Technology tags |
| `repo` | `string` | No | GitHub `owner/repo` |
| `url` | `string` | No | Live deployment URL |
| `version` | `string` | No | Current version |
| `lastCommit` | `string` | No | Git SHA |
| `lastCommitMessage` | `string` | No | First line of commit message |
| `lastCommitAuthor` | `string` | No | Commit author name |
| `lastActivity` | `string` | No | ISO 8601 timestamp (defaults to now) |

**Example**:
```bash
curl -X POST https://gorzelic.net/api/internal/projects \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{
    "slug": "my-project",
    "name": "My Project",
    "description": "Does something cool.",
    "status": "active",
    "tech": ["python", "gcp"],
    "repo": "bgorzelic/my-project"
  }'
```

**Response** `201`:
```json
{
  "project": { ... }
}
```

**Response** `400`:
```json
{
  "error": "slug is required (lowercase alphanumeric with hyphens)."
}
```

---

### Update Project

```
PUT /projects/{slug}
```

**Auth**: Required (Bearer token)

**Body** (JSON) — all fields optional, only provided fields are updated:

| Field | Type | Description |
|-------|------|-------------|
| `name` | `string` | Display name |
| `description` | `string` | One-line description |
| `status` | `string` | `"active"`, `"paused"`, or `"completed"` |
| `tech` | `string[]` | Technology tags (replaces existing) |
| `repo` | `string` | GitHub `owner/repo` |
| `url` | `string` | Live deployment URL |
| `version` | `string` | Current version |
| `lastCommit` | `string` | Git SHA |
| `lastCommitMessage` | `string` | Commit message |
| `lastCommitAuthor` | `string` | Author name |

`lastActivity` is auto-set to the current time on every update.

**Example**:
```bash
curl -X PUT https://gorzelic.net/api/internal/projects/my-project \
  -H "Authorization: Bearer $ADMIN_SECRET" \
  -H "Content-Type: application/json" \
  -d '{"status": "paused"}'
```

**Response** `200`:
```json
{
  "project": { ... }
}
```

---

### Delete Project

```
DELETE /projects/{slug}
```

**Auth**: Required (Bearer token)

**Example**:
```bash
curl -X DELETE https://gorzelic.net/api/internal/projects/my-project \
  -H "Authorization: Bearer $ADMIN_SECRET"
```

**Response** `200`:
```json
{
  "deleted": true
}
```

---

## Webhook

### GitHub Webhook Receiver

```
POST /webhook/github
```

**Auth**: HMAC-SHA256 signature via `X-Hub-Signature-256` header

This endpoint is called by GitHub automatically. You don't call it directly — configure the webhook in your repo settings.

**Supported events**:

| Event | Action |
|-------|--------|
| `push` | Updates commit info and last activity |
| `release` | Updates version and last activity |

**Matching**: The webhook finds the project by comparing `payload.repository.full_name` against each project's `repo` field. If no match is found, the event is silently skipped.

**Response** `200` (matched):
```json
{
  "ok": true,
  "updated": "my-project",
  "event": "push"
}
```

**Response** `200` (no match):
```json
{
  "ok": true,
  "skipped": "no matching project"
}
```

**Response** `401`:
```json
{
  "error": "Invalid signature."
}
```
