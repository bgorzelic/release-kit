# Customization Guide

> How to adapt release-kit workflow templates for your specific project.

## Choosing a Template

| If your project is... | Use this template |
|----------------------|-------------------|
| Node.js / TypeScript with package.json | `release-node.yml` |
| Python with pyproject.toml or setup.cfg | `release-python.yml` |
| Go with go.mod | `release-go.yml` |
| Terraform / Infrastructure as Code | `release-terraform.yml` |
| Anything else, or you just want announcements | `release-minimal.yml` |

## Customization Points

Every template uses `# <<< CUSTOMIZE` comments to mark the lines you should review. Here's what each one means:

### CI Check Job

The `ci-check` job is the quality gate. Adapt it to your project's tooling:

#### Node.js variants

```yaml
# Default (npm + eslint + tsc + vitest)
- run: npm ci
- run: npx eslint --max-warnings 0 .
- run: npx tsc --noEmit
- run: npm test

# pnpm + biome + vitest
- run: pnpm install --frozen-lockfile
- run: pnpm biome check .
- run: npx tsc --noEmit
- run: pnpm test

# yarn + next lint
- run: yarn install --frozen-lockfile
- run: yarn next lint
- run: yarn test
```

#### Python variants

```yaml
# ruff + mypy + pytest
- run: pip install -r requirements.txt
- run: ruff check .
- run: mypy .
- run: pytest

# uv + ruff + pytest
- run: pip install uv && uv pip install -r requirements.txt
- run: ruff check .
- run: pytest --cov

# Poetry
- run: pip install poetry && poetry install
- run: poetry run ruff check .
- run: poetry run pytest
```

#### Go variants

```yaml
# Standard
- run: go vet ./...
- uses: golangci/golangci-lint-action@v6
- run: go test -race ./...

# With coverage
- run: go test -race -coverprofile=coverage.out -covermode=atomic ./...
```

### Version Bump Job

The `bump-version` job updates the version file. Skip or modify based on your project:

| Project type | Version file | Bump method |
|-------------|-------------|-------------|
| Node.js | `package.json` | `npm version X.Y.Z --no-git-tag-version` |
| Python (pyproject.toml) | `pyproject.toml` | `sed` replacement |
| Python (setup.cfg) | `setup.cfg` | `sed` replacement |
| Python (__version__) | `src/pkg/__init__.py` | `sed` replacement |
| Go | None (uses git tags) | Remove this job entirely |
| Terraform | None | Remove this job entirely |

To **remove version bumping**, delete the `bump-version` job and change `needs: bump-version` to `needs: ci-check` in the announce job.

### Tweet Text

The tweet template is in the `announce-twitter` job. Customize the text:

```javascript
// Default
const tweetText = `${process.env.REPO_NAME} ${process.env.RELEASE_TAG} is live!\n\nRelease notes: ${process.env.RELEASE_URL}\n\n#buildinpublic #opensource`;

// With project URL
const tweetText = `${process.env.REPO_NAME} ${process.env.RELEASE_TAG} released!\n\nTry it: https://my-project.com\nChangelog: ${process.env.RELEASE_URL}\n\n#buildinpublic`;

// Detailed
const tweetText = `New release: ${process.env.REPO_NAME} ${process.env.RELEASE_TAG}\n\nKey changes:\n- Feature A\n- Fix B\n\n${process.env.RELEASE_URL}`;
```

Available environment variables in the announce step:

| Variable | Example |
|----------|---------|
| `RELEASE_TAG` | `v1.2.0` |
| `RELEASE_URL` | `https://github.com/bgorzelic/my-project/releases/tag/v1.2.0` |
| `REPO_NAME` | `my-project` |

### Hashtags per Stack

Recommended hashtags by project type:

| Stack | Suggested hashtags |
|-------|--------------------|
| Node.js / TypeScript | `#buildinpublic #nodejs #typescript` |
| Next.js | `#buildinpublic #nextjs #react #webdev` |
| Python | `#buildinpublic #python #opensource` |
| Go | `#buildinpublic #golang #opensource` |
| Terraform | `#buildinpublic #terraform #iac #devops` |
| AI/ML | `#buildinpublic #ai #machinelearning` |

## Adding a New Social Media Platform

Each platform is an independent job. To add one:

1. Add a new job after `announce-twitter`
2. Follow the pattern: check secrets → skip if missing → post
3. Use `needs: bump-version` (or `needs: ci-check` if no version bump)
4. Guard with `if: ${{ github.event_name == 'release' && !github.event.release.prerelease }}`

Template:

```yaml
announce-newplatform:
  name: Post to NewPlatform
  needs: bump-version
  if: ${{ github.event_name == 'release' && !github.event.release.prerelease }}
  runs-on: ubuntu-latest
  steps:
    - name: Check secrets
      id: check
      env:
        HAS_KEY: ${{ secrets.NEWPLATFORM_TOKEN }}
      run: |
        if [ -z "$HAS_KEY" ]; then
          echo "::warning::NewPlatform secrets not configured, skipping"
          echo "skip=true" >> "$GITHUB_OUTPUT"
        else
          echo "skip=false" >> "$GITHUB_OUTPUT"
        fi

    - name: Post
      if: steps.check.outputs.skip != 'true'
      env:
        NEWPLATFORM_TOKEN: ${{ secrets.NEWPLATFORM_TOKEN }}
        RELEASE_TAG: ${{ github.event.release.tag_name }}
        RELEASE_URL: ${{ github.event.release.html_url }}
        REPO_NAME: ${{ github.event.repository.name }}
      run: |
        # Platform-specific posting logic here
        echo "Posted to NewPlatform"
```

## Disabling Components

### No CI gate

Delete the `ci-check` job. Change `needs: ci-check` → remove `needs` from `bump-version`.

### No version bump

Delete the `bump-version` job. Change `needs: bump-version` → `needs: ci-check` in announce jobs.

### No Twitter

Don't set the Twitter secrets. The job auto-skips.

### Announce only (no CI, no bump)

Use `release-minimal.yml` — it only has the announce job.
