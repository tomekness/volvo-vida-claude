Snapshot der VIDA VM nehmen, vorhandene Snapshots auflisten oder einen löschen.

**Ohne Argument:** Frage zuerst nach einem sinnvollen Namen für den Snapshot
(z.B. "nach-sprachumstellung", "vor-diagnose", "baseline-setup").

```bash
REPO=$(git rev-parse --show-toplevel)
$REPO/scripts/vida_snapshot "$SNAPSHOT_NAME"
```

**Mit Argument:** Direktes Ausführen:

```bash
REPO=$(git rev-parse --show-toplevel)
$REPO/scripts/vida_snapshot $ARGUMENTS
```

Mögliche Argumente:
- `[name]` — Snapshot mit dem genannten Namen erstellen
- `--list` — Alle vorhandenen Snapshots anzeigen
- `--delete <name>` — Snapshot löschen (Script fragt nach Bestätigung)

**Nach erfolgreichem Snapshot:** Prüfe ob der neue Snapshot als `DEFAULT_SNAPSHOT`
in `scripts/config.sh` eingetragen werden soll (damit `vida_reset` ohne Argument
diesen Snapshot verwendet). Falls ja: kurzen Hinweis ausgeben.
