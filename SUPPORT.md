# Support

Need help with Heisenberg Team? This document explains the fastest path.

## Before Opening an Issue

1. Read [README.md](README.md)
2. Follow [SETUP.md](SETUP.md)
3. Check [docs/README.md](docs/README.md)
4. Review [docs/faq.md](docs/faq.md)
5. Run the local smoke test:

```bash
bash scripts/smoke-test.sh
```

## Best Channel for Each Problem

### Bug report
Open a GitHub Issue and include:
- what you expected
- what happened instead
- exact command or file path
- OpenClaw version
- OS and shell
- sanitized logs or screenshots

### Documentation gap
Open a GitHub Issue with:
- the page you followed
- the confusing or missing step
- the command or screen where you got blocked

### Installation problem
Include:
- output of `openclaw status`
- output of `bash scripts/smoke-test.sh`
- whether you used the wizard or manual setup
- whether this is a fresh install or attach-existing flow

### Security issue
Do not post it publicly. Follow [SECURITY.md](SECURITY.md).

## What to Sanitize Before Sharing

Remove or replace:
- API keys
- bot tokens
- personal names, IDs, emails
- private file paths if they reveal identity
- internal chat links or invite links

Use placeholders like `{{TOKEN}}`, `{{OWNER_NAME}}`, and `<workspace-path>`.

## Project Scope

This repository supports:
- multi-agent templates for OpenClaw
- team roles, skills, and coordination rules
- setup, onboarding, and maintenance scripts

This repository does not provide support for:
- third-party API outages
- private custom forks you do not share
- provider billing problems

## Suggested Debug Order

1. `openclaw status`
2. `bash scripts/smoke-test.sh`
3. `docs/faq.md`
4. `docs/linux-setup.md` if you are on Linux or WSL
5. GitHub Issue with sanitized details

## Response Expectations

Maintainers and contributors help on a best-effort basis. For the fastest turnaround, provide a minimal reproducible case and clean logs.
