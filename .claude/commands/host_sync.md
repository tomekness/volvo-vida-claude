Sync the diagnostics host machine with the central git repo — commit and push any changes on the host, then pull locally.

## What it does

1. SSH into the host machine
2. If there are uncommitted changes on the host: `git add -A`, commit with timestamp, push
3. `git pull` on the host so it's up to date
4. `git pull` locally so both sides are in sync

## Run

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
bash "$REPO/scripts/host_sync"
```

## When to use

- After working directly on the host (manual file edits, screenshots placed there)
- Before starting a new session to make sure local and host are in sync
- After any VIDA readout or repair session as a final cleanup step

## Notes

- Uses `SSH_HOST`, `SSH_USER`, `SSH_KEY`, `SSH_PORT`, and `REMOTE_REPO_PATH` from `scripts/config.sh`
- Safe to run even if there are no changes on the host — it will just pull and exit
