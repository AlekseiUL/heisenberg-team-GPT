# Offline verification boundary

Preserve shared references/scripts/config examples on repeated additive deploy.

## Reproduce

`python3 -m unittest discover -s tests -v`

Shared upstream: heisenberg-team, only paths in shared-components.lock.json. Keep GPT model defaults and agent content variant-owned. No automatic remote sync. No native uninstall; fixture rollback is snapshot restore; snapshot before --force.

## Rollback

Review the commit diff and use a new checkout of the pre-change commit for source rollback. Keep user data and live installations untouched. A source rollback is not permission to restore unsafe network exposure or bypass approval.
