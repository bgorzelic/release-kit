# Contributing to release-kit

Thanks for helping make releases more repeatable. Contributions should preserve the central promise:
a release is announced only after its declared verification gate succeeds.

## Start here

1. Read the architecture and onboarding documentation in `docs/`.
2. Open an issue or Discussion before changing workflow behavior or secret handling.
3. Branch from `main` and keep the change limited to one concern.
4. Test changed shell scripts with ShellCheck and changed workflows with actionlint.

## Safety rules

- Never commit tokens, webhook secrets, signing keys, or copied production configuration.
- Treat repository, tag, release-note, and webhook content as untrusted input.
- Keep social posting opt-in and non-blocking.
- Do not weaken the CI gate to make a release pass.
- Preserve a manual recovery path when automation fails.

## Pull requests

Explain what changed, which stack templates are affected, and how the behavior was verified. Include a
sample event or dry run for workflow logic where practical. Use Conventional Commits and update the
documentation whenever contributor-facing behavior changes.

Security vulnerabilities belong in a private GitHub security advisory, not a public issue.
