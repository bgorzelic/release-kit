# Social Media Platforms

> Integration guide and roadmap for release announcements.

## Current: X/Twitter

**Status**: Live and tested

### How it works

- Uses Twitter API v2 (`POST /2/tweets`)
- Authenticates via OAuth 1.0a (HMAC-SHA1 signature)
- Runs inline as a Node.js script in GitHub Actions (no external dependencies)
- Skips gracefully if secrets aren't configured

### Required secrets

| Secret | Description |
|--------|-------------|
| `TWITTER_API_KEY` | OAuth consumer key (from Twitter Developer Portal → App → Keys and tokens) |
| `TWITTER_API_SECRET` | OAuth consumer secret |
| `TWITTER_ACCESS_TOKEN` | OAuth access token (with Read and Write permissions) |
| `TWITTER_ACCESS_SECRET` | OAuth access token secret |

### Setup

1. Go to [developer.x.com](https://developer.x.com)
2. Create or select an app
3. Under **User authentication settings**, enable **Read and Write**
4. Under **Keys and tokens**, generate all 4 credentials
5. Set them as GitHub secrets (org or repo level)

### Behavior

- Only fires on `release` events (not `workflow_dispatch`)
- Skips pre-releases automatically
- Posts the repo name, version, and release notes URL

---

## Planned: LinkedIn

**Status**: Not yet implemented

### Approach

LinkedIn API v2 requires OAuth 2.0 with the `w_member_social` scope for personal posts or `w_organization_social` for company page posts.

### Required secrets (planned)

| Secret | Description |
|--------|-------------|
| `LINKEDIN_ACCESS_TOKEN` | OAuth 2.0 Bearer token |
| `LINKEDIN_AUTHOR_URN` | `urn:li:person:XXXXX` or `urn:li:organization:XXXXX` |

### API endpoint

```
POST https://api.linkedin.com/v2/ugcPosts
Content-Type: application/json
Authorization: Bearer $LINKEDIN_ACCESS_TOKEN
```

### Challenges

- LinkedIn OAuth 2.0 tokens expire (60 days for 3-legged flow)
- May need a refresh token rotation mechanism
- Company page posting requires admin approval

---

## Planned: Bluesky

**Status**: Not yet implemented

### Approach

Bluesky uses the AT Protocol. Authentication is via app passwords (no OAuth needed).

### Required secrets (planned)

| Secret | Description |
|--------|-------------|
| `BLUESKY_HANDLE` | Your Bluesky handle (e.g., `brian.bsky.social`) |
| `BLUESKY_APP_PASSWORD` | App password from Settings → App Passwords |

### API endpoint

```
POST https://bsky.social/xrpc/com.atproto.repo.createRecord
```

### Example post payload

```json
{
  "repo": "brian.bsky.social",
  "collection": "app.bsky.feed.post",
  "record": {
    "$type": "app.bsky.feed.post",
    "text": "my-project v1.0.0 released!",
    "createdAt": "2026-02-26T00:00:00Z",
    "facets": [
      {
        "index": {"byteStart": 30, "byteEnd": 60},
        "features": [{"$type": "app.bsky.richtext.facet#link", "uri": "https://..."}]
      }
    ]
  }
}
```

### Advantages

- App passwords don't expire
- No OAuth dance needed
- Simple REST API

---

## Planned: Discord

**Status**: Not yet implemented

### Approach

Discord webhooks are the simplest integration — just a POST to a webhook URL.

### Required secrets (planned)

| Secret | Description |
|--------|-------------|
| `DISCORD_WEBHOOK_URL` | Full webhook URL from Discord channel settings |

### Example

```bash
curl -X POST "$DISCORD_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{"content": "my-project v1.0.0 released! https://github.com/..."}'
```

### Advantages

- No authentication complexity — just a URL
- Rich embeds supported
- Can target specific channels

---

## Planned: Mastodon

**Status**: Not yet implemented

### Approach

Mastodon uses OAuth 2.0. Each instance has its own API.

### Required secrets (planned)

| Secret | Description |
|--------|-------------|
| `MASTODON_INSTANCE` | Instance URL (e.g., `https://mastodon.social`) |
| `MASTODON_ACCESS_TOKEN` | OAuth 2.0 Bearer token |

### API endpoint

```
POST https://{instance}/api/v1/statuses
Authorization: Bearer $MASTODON_ACCESS_TOKEN
```

---

## Platform Priority

Based on audience reach and implementation complexity:

| Priority | Platform | Complexity | Audience |
|----------|----------|-----------|----------|
| 1 (done) | X/Twitter | Medium (OAuth 1.0a) | Developer community |
| 2 | Bluesky | Low (app password) | Growing tech community |
| 3 | Discord | Low (webhook URL) | Project communities |
| 4 | LinkedIn | High (token expiry) | Professional network |
| 5 | Mastodon | Medium (OAuth 2.0) | FOSS community |

## Adding Your Own Platform

See [CUSTOMIZATION.md](CUSTOMIZATION.md#adding-a-new-social-media-platform) for the template.
