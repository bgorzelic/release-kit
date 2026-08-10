# release-kit

## What this is

`release-kit` is reusable release automation for the gorzelic.net ecosystem. It provides copy-in GitHub Actions templates for Node.js/TypeScript, Python, Go, Terraform, and minimal release workflows, plus Bash helpers for project onboarding and GitHub secret setup. (Source: `README.md`, checked 2026-08-05.)

## Setup / install

There is no package manifest or project-wide dependency installation step. For the operational scripts, install the prerequisites documented by the repo:

```bash
brew install gh jq curl
```

Before running `./scripts/onboard-project.sh`, export `ADMIN_SECRET` and `GITHUB_WEBHOOK_SECRET`. Run `./scripts/setup-secrets.sh --repo OWNER/REPO` or `./scripts/setup-secrets.sh --org ORG` to configure the optional X/Twitter announcement credentials through GitHub. Never place credential values in repository files. (Sources: `README.md`, `scripts/onboard-project.sh`, and `scripts/setup-secrets.sh`, checked 2026-08-05.)

## Build / test / lint

No build step or automated test suite was found. The repository's CI performs two lint checks:

```bash
./actionlint -color -ignore 'SC2016:' workflows/*.yml .github/workflows/*.yml
shellcheck scripts/*.sh
```

CI installs actionlint 1.7.12 before running the first command:

```bash
bash <(curl -sSfL https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash) 1.7.12
```

(Source: `.github/workflows/ci.yml`, checked 2026-08-05.)

## Code style / conventions

- Shell scripts use Bash, `set -euo pipefail`, uppercase variables, and small logging helpers. Preserve those patterns when editing scripts. (Source: `scripts/onboard-project.sh` and `scripts/setup-secrets.sh`, checked 2026-08-05.)
- Workflow templates mark consumer-specific edits with `# <<< CUSTOMIZE`; retain those markers where downstream repositories must adapt commands or configuration. (Source: `workflows/*.yml`, checked 2026-08-05.)
- Release tags are strict semantic versions in the form `vX.Y.Z`. (Source: `README.md` and `workflows/*.yml`, checked 2026-08-05.)
- The observed history uses conventional commit prefixes such as `docs:`, `ci:`, `chore:`, and `feat:`. Continue using conventional commits. (Source: git history through commit `c243736`, checked 2026-08-05.)

## Working with multiple agents here

This repo can be worked on by multiple parallel Claude Code or Codex agents launched through this machine's `launch-agents` tool. Each agent receives its own git worktree automatically; do not create a branch manually for that workflow.

For multi-agent tasks, check the shared coordination database for file claims before editing any file another agent may be touching. Keep claims scoped to the files needed for the task, and use conventional commits as established by the repository history.

Never commit secrets. This repository currently has no `.gitignore`, so `.env` and credential files are not confirmed as ignored; inspect the effective ignore rules before assuming any sensitive file is safe from Git tracking. (Source: top-level repository inspection, checked 2026-08-05.)
