Markiert eine Reparatur als erledigt: aktualisiert den Reparatur-Log, verschiebt den Ordner nach `_done/` und synchronisiert den Host.

## Argument

`$ARGUMENTS` = `<ordnername> <Bezeichnung>`

Beispiele:
- `abblendlicht_vorne "Abblendlicht vorne"`
- `lambda_sonde "Lambda-Sonde vorne"`

- **ordnername**: Ordner unter `repairs/` (exakter Name)
- **Bezeichnung**: Lesbarer Name für den Log (mit Anführungszeichen falls Leerzeichen)

---

## Ablauf

### 1. Konfiguration und Argumente

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
ARGS="$ARGUMENTS"
ORDNER=$(echo "$ARGS" | awk '{print $1}')
BEZEICHNUNG=$(echo "$ARGS" | sed 's/^[^ ]* //')
DATUM=$(date +%Y-%m-%d)
```

Prüfen ob Ordner existiert:
```bash
ls "$REPO/repairs/$ORDNER/" || echo "FEHLER: Ordner nicht gefunden"
```

---

### 2. reparatur_log.md aktualisieren

In `repairs/reparatur_log.md` drei Stellen bearbeiten:

**a) Header-Zeile:**
```
_Letzte Aktualisierung: DATUM — BEZEICHNUNG erledigt_
```

**b) Übersichtstabelle** — Zeile mit dem Ordnernamen:
- Status durchstreichen + ✅ Erledigt
- Link auf `_done/<ordnername>/` aktualisieren
- Datum eintragen: `Reparatur abgeschlossen DATUM`

**c) Details-Abschnitt** — Abschnitt `### N — BEZEICHNUNG` auf Kurzform:
```markdown
### ~~N — BEZEICHNUNG~~ ✅ Erledigt (DATUM)

**Abgeschlossen:** DATUM
→ [`_done/ORDNER/README.md`](_done/ORDNER/README.md)
```

**d) Erledigt-Abschnitt** — Neuen Eintrag VOR dem ersten bestehenden einfügen:
```markdown
### ~~BEZEICHNUNG~~ ✅

**Abgeschlossen:** DATUM
→ [`_done/ORDNER/`](_done/ORDNER/README.md)

```

---

### 3. Ordner verschieben

```bash
git -C "$REPO" mv "repairs/$ORDNER" "repairs/_done/$ORDNER"
```

Prüfen ob verschoben:
```bash
ls "$REPO/repairs/_done/$ORDNER/"
```

---

### 4. Commit und Push

```bash
git -C "$REPO" add repairs/reparatur_log.md
git -C "$REPO" commit -m "Done: $BEZEICHNUNG — als erledigt markiert, nach _done/ verschoben"
git -C "$REPO" push
```

---

### 5. Host synchronisieren

```bash
ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" \
  "git -C $REMOTE_REPO_PATH pull"
```

---

## Abschlusskontrolle

- [ ] `repairs/_done/<ordner>/` existiert
- [ ] `repairs/<ordner>/` nicht mehr vorhanden
- [ ] `reparatur_log.md`: Zeile zeigt ✅ Erledigt + Link auf `_done/`
- [ ] `reparatur_log.md`: Details-Abschnitt auf Kurzform reduziert
- [ ] `reparatur_log.md`: Erledigt-Abschnitt enthält neuen Eintrag
- [ ] Git push erfolgreich, Host pull erfolgreich

## Ausgabe

```
✅ BEZEICHNUNG als erledigt markiert
   → repairs/ORDNER/ → repairs/_done/ORDNER/
   → reparatur_log.md aktualisiert
   → Host synchronisiert
```
