Führe einen vollständigen VIDA Diagnose-Readout durch. Kein User-Input nötig — alles automatisch.

## Konfiguration laden

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
SSH_CMD="ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST"
SCAN_DATE=$(date +%Y-%m-%d)
DATE_DIR="$REPO/readouts/vida/$SCAN_DATE"
```

Alle folgenden SSH-Befehle verwenden `$SSH_CMD`, alle VM-Operationen `$VM_NAME`, alle Pfade `$REPO`.

## Ordnerstruktur für diesen Scan

```
readouts/vida/YYYY-MM-DD/
  scanNN_grund.md          ← Auswertungsdatei
  dtc_raw.txt              ← Rohdaten SQL DTC-Export
  freeze_raw.txt           ← Rohdaten SQL Freeze-Frame-Export
  sessions_raw.txt         ← Rohdaten SQL Session-Übersicht
  freeze_ECM_XXXX.txt      ← Freeze Frame je Code (eine Datei pro DTC)
  printouts/               ← VIDA-Drucke als PDF (konvertiert aus XPS)
  screenshots/             ← Screenshots vom Host
```

Beim Start sofort anlegen:
```bash
mkdir -p "$DATE_DIR/screenshots" "$DATE_DIR/printouts"
```

## Dein Ablauf

### 1. VM-Status prüfen und ggf. starten

```bash
$SSH_CMD "vboxmanage showvminfo '$VM_NAME' | grep '^State'"
```

- Wenn "powered off" oder "aborted": `/vida_start` ausführen und 90 Sekunden warten
- Wenn "running": weiter zu Schritt 2
- Wenn "stopping": warte 30s, dann neu prüfen

### 2. NAT-Port-Forwarding für SQL aktivieren

```bash
$SSH_CMD \
  "vboxmanage controlvm '$VM_NAME' natpf1 'sqlserver,tcp,,$SQL_PORT_NAT,,1433'" 2>/dev/null || true
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
$SSH_CMD \
  'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "sqlcmd -S .\\VIDA -d DiagSwdlSession -Q \"SELECT r.Id, r.Timestamp, COUNT(d.Id) AS CodeCount FROM DtcReadout r LEFT JOIN Dtc d ON d.fkDtcReadoutId=r.Id GROUP BY r.Id, r.Timestamp ORDER BY r.Id\" -o Z:\\sessions_out.txt"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'
sleep 6
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/sessions_out.txt"
```

Ergebnis als `sessions_raw.txt` in Datumsordner kopieren:
```bash
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/sessions_out.txt" > "$DATE_DIR/sessions_raw.txt"
```

### 5. Lokalen Stand prüfen — welche Sessions sind bereits dokumentiert?

```bash
# Sucht rekursiv in allen Datumsunterordnern
grep -rh "fkDtcReadoutId" "$REPO/readouts/vida/" 2>/dev/null \
  | grep -oP '\b\d{1,5}\b' | sort -nu | tail -1
```

**Ergebnis:** Höchste bereits dokumentierte Session-ID = `LETZTE_ID`

Vergleiche mit DB-Sessions aus Schritt 4:
- Sessions mit ID > `LETZTE_ID` → **NEU, abrufen**
- Sessions mit ID ≤ `LETZTE_ID` → bereits dokumentiert, überspringen

Falls alle DB-Sessions bereits dokumentiert: Nutzer informieren und abbrechen.

### 6. DTCs und Freeze Frames für neue Sessions abrufen

**DTC-Export:**
```bash
$SSH_CMD \
  'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "sqlcmd -S .\\VIDA -d DiagSwdlSession -Q \"SELECT e.EcuIdentifier, d.HexValue, d.Status, d.Text, d.permanentStatus, d.MileageKilometres, d.fkDtcReadoutId FROM Dtc d JOIN EcuInfo e ON e.Id=d.fkEcuInfoId WHERE d.fkDtcReadoutId > LETZTE_ID ORDER BY d.fkDtcReadoutId, e.EcuIdentifier, d.HexValue\" -o Z:\\dtc_out.txt"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'
sleep 8
```

**Freeze-Frame-Export:**
```bash
$SSH_CMD \
  'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "sqlcmd -S .\\VIDA -d DiagSwdlSession -Q \"SELECT e.EcuIdentifier, d.HexValue, d.fkDtcReadoutId, f.name, f.value FROM FreezeFrameParam f JOIN Dtc d ON d.Id=f.fkDtcId JOIN EcuInfo e ON e.Id=d.fkEcuInfoId WHERE d.fkDtcReadoutId > LETZTE_ID ORDER BY d.fkDtcReadoutId, e.EcuIdentifier, d.HexValue, f.name\" -o Z:\\freeze_out.txt"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'
sleep 10
```

**Wichtig:** `LETZTE_ID` im SQL-String mit der tatsächlichen Zahl ersetzen.

**Timestamp prüfen** — falls Dateien älter als heute: CMD-Befehl hat nicht funktioniert:
```bash
$SSH_CMD "stat $REMOTE_DOWNLOADS_PATH/dtc_out.txt $REMOTE_DOWNLOADS_PATH/freeze_out.txt"
```

**Rohdaten in Datumsordner kopieren:**
```bash
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/dtc_out.txt"    > "$DATE_DIR/dtc_raw.txt"
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/freeze_out.txt" > "$DATE_DIR/freeze_raw.txt"
```

### 7. Screenshots vom Host kopieren

**Suchpfade** (aus config.sh: `$REMOTE_SCREENSHOTS_PATH`, `$REMOTE_DOWNLOADS_PATH`):

Screenshots nach Scan-Datum filtern — Dateien die `$SCAN_DATE` im Namen haben ODER am Scan-Tag geändert wurden:

```bash
$SSH_CMD "
find \"$REMOTE_SCREENSHOTS_PATH\" \"$REMOTE_DOWNLOADS_PATH\" \
  -maxdepth 3 \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' \) \
  2>/dev/null | while read f; do
    fname=\$(basename \"\$f\")
    mdate=\$(date -r \"\$f\" +%Y-%m-%d 2>/dev/null)
    if echo \"\$fname\" | grep -q '$SCAN_DATE' || [ \"\$mdate\" = '$SCAN_DATE' ]; then
      echo \"\$f\"
    fi
  done | sort
"
```

Gefundene Dateien per ssh+cat kopieren:

```bash
# Für jede gefundene Datei:
while IFS= read -r remote_path; do
  local_name=$(basename "$remote_path")
  $SSH_CMD "cat \"$remote_path\"" > "$DATE_DIR/screenshots/$local_name"
  echo "Screenshot: $local_name"
done <<< "$FOUND_SCREENSHOTS"
```

Falls keine Screenshots gefunden: kurz melden und weitermachen (kein Fehler).

### 8. XPS-Drucke zu PDF konvertieren und in printouts/ legen

**xpstopdf sicherstellen:**
```bash
$SSH_CMD "test -f /tmp/gxps_tools/usr/bin/xpstopdf && echo OK || \
  (cd /tmp && apt-get download libgxps-utils 2>/dev/null && \
   dpkg -x libgxps-utils*.deb /tmp/gxps_tools && echo OK)"
```

**Schritt 1 — XPS in Windows suchen** (sucht in allen User-Ordnern):

```bash
# Windows CMD: alle XPS mit Scan-Datum in C:\Users\ suchen → Pfade nach Z:\xps_found.txt
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputstring \
  'dir /s /b C:\\Users\\*$SCAN_DATE*.xps > Z:\\xps_found.txt 2>NUL'"
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputscancode 1c 9c"
sleep 6
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/xps_found.txt"
```

Falls kein Treffer mit Datum im Namen — nach Dateien vom Scan-Tag suchen:
```bash
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputstring \
  'forfiles /p C:\\Users /s /m *.xps /d +0 /c \"cmd /c echo @path\" > Z:\\xps_found.txt 2>NUL'"
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputscancode 1c 9c"
sleep 6
```

**Schritt 2 — Gefundene XPS nach Z:\ kopieren:**
```bash
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputstring \
  'for /f \"tokens=*\" %f in (Z:\\xps_found.txt) do copy \"%f\" Z:\\ '"
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputscancode 1c 9c"
sleep 5
$SSH_CMD "ls $REMOTE_DOWNLOADS_PATH/*.xps 2>/dev/null | sort"
```

**Schritt 3 — Konvertieren auf Host und lokal kopieren:**
```bash
$SSH_CMD "
mkdir -p /tmp/vida_pdfs_$SCAN_DATE
for xps in $REMOTE_DOWNLOADS_PATH/*.xps; do
  [ -f \"\$xps\" ] || continue
  base=\$(basename \"\$xps\" .xps)
  out=\"/tmp/vida_pdfs_$SCAN_DATE/\${base}.pdf\"
  [ -f \"\$out\" ] && continue
  /tmp/gxps_tools/usr/bin/xpstopdf \"\$xps\" \"\$out\" 2>/dev/null && \
    echo \"OK: \${base}.pdf\" || echo \"FEHLER: \$base\"
done
ls /tmp/vida_pdfs_$SCAN_DATE/
"

# PDFs lokal ablegen
scp -i "$SSH_KEY" -P "$SSH_PORT" \
  "$SSH_USER@$SSH_HOST:/tmp/vida_pdfs_$SCAN_DATE/*.pdf" \
  "$DATE_DIR/printouts/" 2>/dev/null || true
```

Falls keine XPS gefunden: kurz melden, weitermachen.

### 9. Freeze Frames aufbereiten — eine Datei pro DTC-Code

Aus `$DATE_DIR/freeze_raw.txt` eine Datei pro ECU+Code erstellen.

**Komprimiert lesen:**
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

Für jeden DTC-Code eine separate Datei anlegen:
```
$DATE_DIR/freeze_ECM_XXXX.txt
$DATE_DIR/freeze_CCM_XXXX.txt
```

Format:
```
# Freeze Frame — ECM XXXX — Session NN (YYYY-MM-DD)
Parameter            | Wert
---------------------|------
Abstand              | ___ km
Motor läuft          | Ja / Nein
Kühlmitteltemperatur | ___ °C
...
```

Wichtige Werte beim Schreiben bewerten (kurzer Kommentar hinter dem Wert):
- LTFT > ±15%: `⚠️ erhöht`
- Gleiche km-Zahl nach Löschung: `⚠️ sofort neu gesetzt = aktiver Defekt`

### 10. Sessions analysieren und vergleichen

**Bekanntes DB-Schema (DiagSwdlSession):**
- `Dtc`: Id, fkDtcReadoutId, fkEcuInfoId, Text, HexValue, Status, permanentStatus, MileageKilometres
- `DtcReadout`: Id, fkWorkshopSessionId, Timestamp, EcuType
- `EcuInfo`: Id, fkWorkshopSessionId, EcuIdentifier, SystemCode
- `FreezeFrameParam`: Id, fkDtcId, name, value

**Für jede neue Session:**
1. Codes gruppieren nach ECU
2. Status: "Permanenter Fehler" oder "Zeitweilig auftretender Fehler"
3. Vergleich mit vorheriger Session (gleicher Tag → vor/nach Löschung):
   - Neu hinzugekommen? Verschwunden? Status geändert?
4. Vergleich mit letztem dokumentierten Scan:
   - Frühere Geistercodes zurückgekehrt?
   - Neue unbekannte Codes?
   - LTFT verändert?

**Muster:**
- Code nach Löschung sofort zurück → **echter Defekt**
- Code nach Löschung weg → **Geistercode**
- Neuer Code → **neue Störung, priorisieren**

**Freeze-Frame-Hinweise:**
- "Abstand" = km **zum Zeitpunkt des Fehlersetzens**
- LTFT > ±15% = Kraftstoff-Trim erhöht
- Gleiche km-Zahl nach Löschung = sofort neu gesetzt = aktiver Defekt

### 11. Scan-MD erstellen

**Dateiname und Pfad — in den Datumsordner:**
```
$DATE_DIR/scanNN_grund.md
```

- `NN`: nächste freie Nummer — zählen mit:
  ```bash
  find "$REPO/readouts/vida" -mindepth 2 -name "scan*.md" | wc -l
  ```
  Dann +1
- `grund`: "scan" wenn Routine, sonst z.B. "nach_loeschung", "nach_reparatur", "vor_umbau"

**Vorlage:** `$REPO/readouts/vida/_template.md` vollständig ausfüllen.

**Relative Links innerhalb der Datei** (da sie im Datumsordner liegt):
- Rohdaten: `dtc_raw.txt`, `freeze_raw.txt` (gleicher Ordner)
- Freeze-Frame-Einzeldateien: `freeze_ECM_XXXX.txt` (gleicher Ordner)
- Printouts: `printouts/NAME.pdf` (Unterordner)
- Screenshots: `screenshots/bild.png` (Unterordner)
- Querverweise auf repairs/: `../../../repairs/KOMPONENTE/analyse.md`

**Wenn mehrere neue Sessions:** Session-Übersichtstabelle einbauen:

```markdown
## Session-Übersicht

| Session | Timestamp | Kontext | ECM | CCM | CEM | ... |
|---------|-----------|---------|-----|-----|-----|-----|
| ID_A    | HH:MM     | Scan vor Löschung | Code1 | | | |
| —       | —         | Löschung durch User | — | — | — | |
| ID_B    | HH:MM     | Scan nach Löschung | Code1 zurück? | | | |
```

Freeze Frames je Code mit Session-ID beschriften.

Kommentarzeile am Ende:
```
**Dein Kommentar:** _(hier eintragen — Symptome, Fahrten, Auffälligkeiten)_
```

### 12. reparatur_log.md abgleichen

Lesen: `$REPO/repairs/reparatur_log.md`

Für jeden offenen Eintrag prüfen ob der neue Scan Neuigkeiten bringt. Falls ja:
- Betroffene Todo-Zeile(n) aktualisieren
- Neuen Code ohne Eintrag: neuen Block anlegen

### 13. fehler_verlauf.md aktualisieren

In `$REPO/readouts/fehler_verlauf.md`:

1. **Verlaufstabelle:** Neue Zeile pro Session-Gruppe
2. **Detail-Tabelle:** "Zuletzt" aktualisieren, Status anpassen
3. Neue Codes → neue Zeile; Geistercodes → `~~durchgestrichen~~`
4. Kommentarzeile `_(Kommentar: …)_` für User stehen lassen

### 14. Commit und Push

Immer am Ende ausführen — auch wenn nur Rohdaten oder Screenshots neu sind:

```bash
git -C "$REPO" add "readouts/vida/$SCAN_DATE/"
git -C "$REPO" add readouts/fehler_verlauf.md repairs/reparatur_log.md
git -C "$REPO" commit -m "Readout $SCAN_DATE: scanNN — N neue Sessions, X Codes"
git -C "$REPO" push

# Host pullen damit beide Seiten synchron sind
$SSH_CMD "git -C $REMOTE_REPO_PATH pull"
```

### 15. Zusammenfassung ausgeben

- Wie viele neue Sessions (DB-Total vs. dokumentiert)
- Neue / verschwundene Codes vs. letztem Scan
- Geistercodes vs. echte Defekte
- **Repair-Log:** Was hat sich verändert?
- Welche Dateien angelegt: scan-MD, Freeze-Frame-Einzeldateien, PDFs, Screenshots
- Ob VM noch läuft
