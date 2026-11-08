Setze die VIDA VM auf einen Snapshot zurück.

Ohne Argument: Default-Snapshot aus config.sh (`DEFAULT_SNAPSHOT`).
Mit Argument: den genannten Snapshot verwenden.
Mit `--list`: alle verfügbaren Snapshots anzeigen.

**Snapshot nehmen** (nicht nur wiederherstellen): `/vida_snapshot`

```bash
REPO=$(git rev-parse --show-toplevel)
$REPO/scripts/vida_reset $ARGUMENTS
```

Melde welcher Snapshot wiederhergestellt wurde und ob die VM danach wieder läuft.
Falls der Snapshot nicht gefunden wird oder kein DEFAULT_SNAPSHOT gesetzt ist,
liste die verfügbaren Snapshots auf und frage den User welchen er verwenden möchte.
