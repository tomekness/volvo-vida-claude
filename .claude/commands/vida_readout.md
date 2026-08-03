Führe einen vollständigen VIDA Diagnose-Readout durch. Kein User-Input nötig — alles automatisch.

## Konfiguration laden

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
SSH_CMD="ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST"
```

Alle folgenden SSH-Befehle verwenden `$SSH_CMD`, alle VM-Operationen `$VM_NAME`, alle Pfade `$REPO`.

## Dein Ablauf

### 1. VM-Status prüfen und ggf. starten

```bash
$SSH_CMD "vboxmanage showvminfo '$VM_NAME' | grep '^State'"
```

- Wenn "powered off" oder "aborted": `/vida_start` ausführen und 90 Sekunden warten
- Wenn "running": weiter zu Schritt 2
- Wenn "stopping": warte 30s, dann `kill -9` auf VBoxHeadless

### 2. NAT-Port-Forwarding für SQL aktivieren

```bash
$SSH_CMD "vboxmanage controlvm '$VM_NAME' natpf1 'sqlserver,tcp,,$SQL_PORT_NAT,,1433'" 2>/dev/null || true
```

### 3. CMD in Windows öffnen (Win+R → cmd)

**Wichtig:** Win+R als kombinierte Taste senden — sonst öffnet sich der Explorer statt Run-Dialog.

```bash
# Escape — evtl. offene Fenster schließen
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 01 81'
sleep 1
# Win+R kombiniert: Win-down, R-down, R-up, Win-up
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode e0 5b 13 93 e0 db'
sleep 2
# "cmd" eintippen + Enter
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "cmd"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'
sleep 3
```

Screenshot machen und prüfen ob CMD offen ist, bevor SQL-Queries gesendet werden.

### 4. Session-Übersicht aus DB holen

```bash
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "sqlcmd -S .\\VIDA -d DiagSwdlSession -Q \"SELECT r.Id, r.Timestamp, COUNT(d.Id) AS CodeCount FROM DtcReadout r LEFT JOIN Dtc d ON d.fkDtcReadoutId=r.Id GROUP BY r.Id, r.Timestamp ORDER BY r.Id\" -o Z:\\sessions_out.txt"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'
sleep 6
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/sessions_out.txt"
```

### 5. Lokalen Stand prüfen — welche Sessions sind bereits dokumentiert?

```bash
grep -r "fkDtcReadoutId" "$REPO/readouts/" | grep -oP '\d+(?=\)|\s*$)' | sort -n | tail -1
```

Alternativ alle Session-IDs aus den Readout-Dateien extrahieren:
```bash
grep -rh "fkDtcReadoutId" "$REPO/readouts/vida/"*.md 2>/dev/null | grep -oP '\b\d{1,4}\b' | sort -nu
```

**Ergebnis:** Höchste bereits dokumentierte Session-ID = `LETZTE_ID`

Vergleiche DB-Sessions mit `LETZTE_ID`:
- Sessions mit ID > `LETZTE_ID` → **NEU, muss abgerufen werden**
- Sessions mit ID ≤ `LETZTE_ID` → bereits dokumentiert, überspringen

Falls alle Sessions bereits dokumentiert: Nutzer informieren und abbrechen.

### 6. DTCs für alle neuen Sessions abrufen

**DTC-Export — alle neuen Sessions in einem Query:**
```bash
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "sqlcmd -S .\\VIDA -d DiagSwdlSession -Q \"SELECT e.EcuIdentifier, d.HexValue, d.Status, d.Text, d.permanentStatus, d.MileageKilometres, d.fkDtcReadoutId FROM Dtc d JOIN EcuInfo e ON e.Id=d.fkEcuInfoId WHERE d.fkDtcReadoutId > LETZTE_ID ORDER BY d.fkDtcReadoutId, e.EcuIdentifier, d.HexValue\" -o Z:\\dtc_out.txt"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'
sleep 8
```

**Freeze-Frame-Export:**
```bash
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "sqlcmd -S .\\VIDA -d DiagSwdlSession -Q \"SELECT e.EcuIdentifier, d.HexValue, d.fkDtcReadoutId, f.name, f.value FROM FreezeFrameParam f JOIN Dtc d ON d.Id=f.fkDtcId JOIN EcuInfo e ON e.Id=d.fkEcuInfoId WHERE d.fkDtcReadoutId > LETZTE_ID ORDER BY d.fkDtcReadoutId, e.EcuIdentifier, d.HexValue, f.name\" -o Z:\\freeze_out.txt"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'
sleep 10
```

**Wichtig:** `LETZTE_ID` im SQL-String mit der tatsächlichen Zahl ersetzen bevor der Befehl gesendet wird.

### 7. Ergebnisse lesen und aufbereiten

```bash
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/dtc_out.txt"
```

Freeze-Frame-Datei komprimiert aufbereiten:
```bash
$SSH_CMD "python3 -c \"
import re
with open('$REMOTE_DOWNLOADS_PATH/freeze_out.txt', 'r', errors='replace') as f:
    lines = f.readlines()
for line in lines:
    parts = re.split(r'  +', line.rstrip())
    parts = [p.strip() for p in parts if p.strip()]
    if parts:
        print(' | '.join(parts))
\""
```

**Timestamp prüfen** — falls Dateien älter als heute sind, hat der CMD-Befehl nicht funktioniert:
```bash
$SSH_CMD "stat $REMOTE_DOWNLOADS_PATH/dtc_out.txt $REMOTE_DOWNLOADS_PATH/freeze_out.txt"
```

### 8. Sessions analysieren und vergleichen

**Bekanntes DB-Schema (DiagSwdlSession):**
- `Dtc`: Id, fkDtcReadoutId, fkEcuInfoId, Text, HexValue, Status, permanentStatus, MileageKilometres
- `DtcReadout`: Id, fkWorkshopSessionId, Timestamp, EcuType
- `EcuInfo`: Id, fkWorkshopSessionId, EcuIdentifier, SystemCode
- `FreezeFrameParam`: Id, fkDtcId, name, value

**Für jede neue Session einzeln auswerten:**

1. Codes gruppieren nach ECU
2. Status je Code: "Permanenter Fehler" oder "Zeitweilig auftretender Fehler"
3. **Vergleich mit vorheriger Session** (gleicher Tag → meist vor/nach Löschung):
   - Neu hinzugekommen? Verschwunden? Status geändert?
4. **Vergleich mit letztem dokumentierten Scan:**
   - Frühere Geistercodes zurückgekehrt? Neue Codes? LTFT verändert?

**Muster erkennen:**
- Code nach Löschung sofort zurück → **echter Defekt**
- Code nach Löschung weg → **Geistercode**
- Code komplett neu → **neue Störung, priorisieren**

Freeze-Frame-Hinweise:
- "Abstand"-Wert = km zum Zeitpunkt der Fehlersetzung
- LTFT > ±15% = erhöhter Kraftstoff-Trim (Lambda/Ansaugsystem prüfen)
- Gleiche km-Zahl in zwei Sessions = aktiver Defekt (sofort neu gesetzt)

### 9. Readout-Datei(en) erstellen

**Eine Datei pro Scan-Tag:**

Dateiname: `readouts/vida/YYYY-MM-DD_scanNN_GRUND.md`
- NN: nächste freie Nummer: `ls "$REPO/readouts/vida/2026-"*.md 2>/dev/null | wc -l`
- GRUND: "scan" wenn kein besonderer Anlass, z.B. "nach_loeschung", "vor_reparatur"

Vorlage: `readouts/vida/_template.md` — vollständig ausfüllen.

**Bei mehreren neuen Sessions:** Session-Übersichtstabelle einbauen:

```markdown
## Session-Übersicht

| Session | Kontext | ECM | CCM | PDM | ... |
|---------|---------|-----|-----|-----|-----|
| ID_A    | Vor Löschung | Code1 | Code2 | ... | |
| —       | Löschung | — | — | — | |
| ID_B    | Nach Löschung | Code1 zurück? | ... | | |

→ Interpretation (Geistercodes vs. echte Defekte)
```

Kommentarzeile am Ende der Bewertung für den User lassen:
```
**Dein Kommentar:** _(hier eintragen — z.B. Symptome, Auffälligkeiten)_
```

### 10. reparatur_log.md abgleichen

Datei lesen: `$REPO/repairs/reparatur_log.md`

Für jeden offenen Eintrag prüfen ob der neue Scan Neuigkeiten bringt. Falls ja:
- Betroffene Todo-Zeile(n) aktualisieren
- Neuen Code ohne Eintrag: neuen Block anlegen

### 11. fehler_verlauf.md aktualisieren

In `$REPO/readouts/fehler_verlauf.md`:

1. **Verlaufstabelle:** Neue Zeile pro Session-Gruppe
2. **Detail-Tabelle** je Code: "Zuletzt" aktualisieren, Status anpassen
3. Neuer Code → neue Zeile; Geistercode → `~~GEISTERCODE~~` vermerken
4. Kommentarzeile `_(Kommentar: …)_` in neuer Verlaufszeile lassen

### 12. Commit und Push

```bash
git -C "$REPO" add readouts/vida/NEUE_DATEI.md readouts/fehler_verlauf.md
git -C "$REPO" commit -m "Readout YYYY-MM-DD: scanNN — N neue Sessions, X Codes"
git -C "$REPO" push
$SSH_CMD "git -C $REMOTE_REPO_PATH pull"
```

### 13. Zusammenfassung ausgeben

- Wie viele neue Sessions gefunden
- Was neu vs. letztem Scan (neue, verschwundene, Status-Änderungen)
- Geistercodes vs. echte Defekte
- Welche Datei angelegt wurde
