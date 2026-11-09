Erstelle eine vollständige Reparaturmappe für eine Fahrzeugkomponente aus VIDA-Daten.

## Argument

`$ARGUMENTS` = Name der Komponente (z.B. "scheibenwischer", "luftqualitätssensor", "lambda sonde vorne", "scheinwerfer vorne")

Daraus:
- Ordnername: Kleinbuchstaben, Leerzeichen → Unterstrich (z.B. `scheibenwischer`, `aqs_sensor`)
- Suchbegriffe für VIDA-DB (deutsch, mehrere Varianten)

## Konfiguration laden

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
SSH_CMD="ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST"
```

---

## Pflichtlektüre vor jeder Aktion

Vor dem ersten SQL-Befehl diese Dateien lesen:

1. **`$REPO/facts/vehicle_facts.md`** — Einzige Quelle der Wahrheit für alle verifizierten Fahrzeug-Spezifika (Pins, Spannungen, Sicherungen, bekannte VCC-Docs). Immer zuerst prüfen ob gesuchte Info hier bereits steht.
2. **`$REPO/repairs/KOMPONENTE/`** — Falls bereits eine Reparaturmappe existiert, vollständig lesen um Duplikate und Widersprüche zu vermeiden.

**QUELLEN-PFLICHT:** Jede Angabe (Pin-Nummer, Kabelfarbe, Spannung, Drehmomentwert, Teilenummer, Steckergröße) in erstellten Dateien **muss** eine Quellenspalte haben — entweder eine VCC-Nummer oder einen Eintrag in `facts/vehicle_facts.md`.

**Fehlende Quelle = Angabe weglassen.** Niemals aus Trainingsdaten ergänzen.

Falls ein gesuchter Wert in VIDA nicht gefunden wird:
- In Dokumentation schreiben: `_(nicht in VIDA gefunden — Quelle prüfen)_`
- Eintrag in `facts/vehicle_facts.md` → Abschnitt "Was NICHT in VIDA gefunden wurde" hinzufügen

---

## Ablauf

### 0. Vorbereitung

Prüfe ob VM läuft:
```bash
$SSH_CMD "vboxmanage showvminfo '$VM_NAME' | grep '^State'"
```
Falls nicht running: `/vida_start` aufrufen, 90s warten.

Ordnerstruktur anlegen:
```bash
mkdir -p "$REPO/repairs/ORDNERNAME/pdfs"
```

---

### 1. VIDA-Dokumente suchen

**1a. Offline-Suche über vida_docs.db (bevorzugt — kein VM-Start nötig):**

230 MB SQLite-DB mit allen VIDA-Dokumenten. Wo sie liegt (lokal oder auf dem Host) und wie sie abgefragt wird, steuert `scripts/config.sh` → `VIDA_DOCS_LOCAL` / `VIDA_DOCS_DB_PATH`. Das Script kümmert sich um alles:

```bash
"$REPO/scripts/vida_docs_query.sh" "SUCHBEGRIFF"
# mit eigenem Limit (Standard: 30):
"$REPO/scripts/vida_docs_query.sh" "SUCHBEGRIFF" 50
```

Mehrere Suchbegriffe probieren (deutsch, Varianten): z.B. `Drosselklappe`, `Drosselklappeneinheit`, `ETM`, `throttle`.
Ergebnisse mit `facts/vehicle_facts.md` → "Bestätigte VIDA-Quelldokumente" abgleichen — bereits bekannte VCC-Nummern zuerst verwenden.

**1b. Live-SQL-Suche in der VM (wenn vida_docs.db fehlt oder mehr Details nötig):**

Suche in `servicerep_${VIDA_LANGUAGE}.Document` nach passenden Titeln.
Sende per CMD in der VM (CMD muss offen sein — ggf. Win+R → cmd, Scancode `e0 5b 13 93 e0 db`):

```
sqlcmd -S .\VIDA -d servicerep_$VIDA_LANGUAGE -Q "SELECT vccNumber, title, path FROM Document WHERE title LIKE '%SUCHBEGRIFF%' ORDER BY vccNumber" -o Z:\repair_search.txt -y 0
```

Ausgabe auf dem Host lesen:
```bash
$SSH_CMD "cat ~/Downloads/repair_search.txt"
```

**Relevante Docs auswählen** (Priorität):
1. Docs mit "auswechseln" / "ersetzen" / "ausbauen" → Hauptanleitung
2. Docs mit "überprüfen" / "prüfen" / "diagnose" → Diagnoseanleitung
3. Docs mit dem Bauteilnamen ohne Verb → Technische Info / Übersicht

**Wichtig — Fahrzeugspezifische Filterung via DocumentProfile:**
Manche Komponenten haben mehrere Varianten je nach Baujahr. Immer mit `DocumentProfile` verifizieren dass das Dokument für das richtige Modelljahr gilt:

```
sqlcmd -S .\VIDA -d servicerep_$VIDA_LANGUAGE -Q "SELECT DISTINCT d.vccNumber, d.title FROM Document d JOIN DocumentProfile dp ON dp.fkDocument = d.Id WHERE d.title LIKE '%SUCHBEGRIFF%' AND dp.fkVehicleModel = $VIDA_VEHICLE_MODEL AND dp.fkModelYear = $VIDA_MODEL_YEAR ORDER BY d.vccNumber" -o Z:\repair_search_filtered.txt -y 0
```

Werte für dieses Fahrzeug (YOUR_VIN_HERE):
- `fkVehicleModel = $VIDA_VEHICLE_MODEL` → aus config.sh (via /vida_init ermittelt)
- `fkModelYear = $VIDA_MODEL_YEAR` → aus config.sh (via /vida_init ermittelt)

Falls die gefilterte Suche zu wenig Treffer liefert: ungefilterte Suche als Fallback, dann manuell auf Baujahr-Kompatibilität prüfen.

---

### 2. XML-Inhalt extrahieren (ZIP-Decode)

Für jedes ausgewählte Dokument:

```
sqlcmd -S .\VIDA -d servicerep_$VIDA_LANGUAGE -Q "SELECT CONVERT(varchar(max), CONVERT(varbinary(max), XmlContent), 1) FROM Document WHERE vccNumber='VCC-XXXXXX-X'" -o Z:\doc_VCCXXXXXX.txt -y 0
```

Auf dem Host per Python dekodieren:
```bash
$SSH_CMD "python3 -c \"
import binascii, zipfile, io, re

def decode_doc(path):
    with open(path, 'r') as f:
        content = f.read()
    m = re.search(r'0x([0-9A-Fa-f]+)', content)
    if not m:
        return None, []
    data = binascii.unhexlify(m.group(1))
    zf = zipfile.ZipFile(io.BytesIO(data))
    for name in zf.namelist():
        xml = zf.read(name).decode('utf-8', errors='replace')
        imgs = re.findall(r'(0900c8af[a-f0-9]{8})_[0-9_]+\.gif', xml)
        refs = re.findall(r'de-DE(0900c8af[a-f0-9]{8})', xml)
        text = re.sub(r'<[^>]+>', ' ', xml)
        text = re.sub(r'  +', ' ', text).strip()
        return text, list(set(imgs)), list(set(refs))
    return None, [], []
\""
```

**Aus dem extrahierten Text identifizieren:**
- Einbauhinweise / Schritte (nummeriert oder mit Absätzen)
- Teilenummern / Bestellnummern (z.B. "Bestellnr. 1161035-9")
- Drehmomente (z.B. "55 Nm")
- Werkzeuge (z.B. "Lambda-Schlüssel 22mm")
- Verweise auf andere Dokumente (`de-DE0900c8af...#KC...`) → **Referenzierte Unterprozeduren**

**QUELLEN-PFLICHT:** Jede Angabe die in die Dokumentation einfliesst, muss aus dem extrahierten XML-Text dieses Schritts stammen. Falls ein gesuchter Wert nicht im Text enthalten ist:
- In Dokumentation schreiben: `_(nicht in VCC-XXXXXX-X enthalten — VIDA-Abfrage erforderlich)_`
- Eintrag in `$REPO/facts/vehicle_facts.md` → "Was NICHT in VIDA gefunden wurde" hinzufügen
- **Nicht aus Trainingsdaten oder anderen Fahrzeugen ergänzen**

---

### 3. Referenzierte Unterprozeduren holen

Die XML-Dokumente enthalten oft Querverweise auf andere Dokumente (z.B. "Scheibenwischer entfernen", "Verkleidung abnehmen"). Diese IDs (`0900c8af...`) müssen auch als Dokumente gefunden und extrahiert werden.

Für jede gefundene Referenz-ID (`0900c8af...`):
```
sqlcmd -S .\VIDA -d servicerep_$VIDA_LANGUAGE -Q "SELECT vccNumber, title, path FROM Document WHERE path LIKE '%0900c8afXXXXXXXX%'" -o Z:\ref_search.txt -y 0
```

Falls Treffer: XML extrahieren wie in Schritt 2. Diese Dokumente kommen in den **Vorbereitungen**-Abschnitt der README und erhalten eigene PDFs.

**QUELLEN-PFLICHT gilt auch für Unterprozeduren:** Jede Angabe aus diesen Dokumenten (Drehmomentwerte, Teilenummern, Schrittfolgen) stammt aus der jeweiligen VCC-Nummer — diese in der Quellenangabe der README explizit aufführen. Niemals Schritte aus Trainingsdaten ergänzen wenn das referenzierte Dokument in VIDA nicht gefunden wird.

---

### 4. Bilder extrahieren

Alle Bild-IDs gesammelt (aus allen Haupt- und Unterdokumenten):

Für jede Bild-ID (`0900c8af...`):
```
bcp "SELECT TOP 1 imageData FROM imagerepository.dbo.LocalizedGraphics WHERE fkGraphic = '0900c8afXXXXXXXX' ORDER BY DATALENGTH(imageData) DESC" queryout Z:\imgXXXXXXXX.gif -S .\VIDA -T -n
```

Auf dem Host den 4-Byte BCP-Prefix entfernen und als saubere GIF-Datei speichern:
```bash
$SSH_CMD "python3 -c \"
with open('$REMOTE_DOWNLOADS_PATH/imgXXXXXXXX.gif','rb') as f:
    data = f.read()
if data[4:7] == b'GIF':
    data = data[4:]
with open('$REMOTE_DOWNLOADS_PATH/clean_imgXXXXXXXX.gif','wb') as f:
    f.write(data)
print(f'OK {len(data)} bytes')
\""
```

Dann per SCP auf lokalen Rechner in `repairs/ORDNERNAME/pdfs/` kopieren.

---

### 5. Teileliste und Werkzeuge

Aus dem extrahierten Text der Dokumente identifizieren und in `repairs/ORDNERNAME/teile_werkzeug.md` schreiben:

**Format:**
```markdown
# Teile & Werkzeug — KOMPONENTE

## Benötigte Teile

| Teil | Volvo Bestellnr. | Beschreibung |
|------|-----------------|-------------|
| Einbaupaste | 1161035-9 | Gewindeeinbaupaste für Lambda-Sonde |
| Dichtring | — | Neuer Dichtring (immer ersetzen) |

## Werkzeuge

| Werkzeug | Spezifikation |
|----------|--------------|
| Lambda-Schlüssel | T9995250, 22mm mit Kabelschlitz |
| Drehmomentschlüssel | bis 55 Nm |

## Drehmomente

| Bauteil | Drehmoment |
|---------|-----------|
| Lambda-Sonde | 55 Nm |

## Hinweise
- Nur kalten Motor bearbeiten
- Gewinde: Einbaupaste auf ganzes Gewinde, NICHT auf Sensorelement
```

---

### 6. Fehleranalyse (falls bekannter DTC)

Prüfe ob im `readouts/` Ordner oder `fehler_verlauf.md` passende Fehlercodes vorhanden:
```bash
grep -ri "KOMPONENTENNAME\|DTCCODE" "$REPO/readouts/"
```

Falls ja: Schreibe `repairs/ORDNERNAME/fehleranalyse.md` mit:

```markdown
# Fehleranalyse — KOMPONENTE

## Bekannte DTCs

| Code | ECU | Beschreibung | Erstmals | Status |
|------|-----|-------------|----------|--------|

## Freeze Frame Analyse
[relevante Freeze-Frame-Daten aus Readout-Dateien]

## Bewertung
[Ist echter Defekt oder Geistercode? Begründung aus Freeze-Frame-Daten]

## Empfehlung
[Tauschen / Reinigen / Beobachten — mit Begründung]
```

---

### 7. PDFs erstellen

Für jede Anleitung eine HTML-Datei erstellen mit:
- VIDA-Quellangabe (VCC-Nummer, Datum)
- Eingebettete Bilder (`<img src="vida_img_XXXX.gif">`)
- Schrittweise Anleitung (strukturiert aus dem extrahierten Text)
- Vollständiges CSS-Styling (Volvo-blau Akzente, lesbare Schrift)

**HTML → PDF via Chrome Headless:**
```bash
google-chrome --headless --disable-gpu --no-sandbox \
  --print-to-pdf=/path/to/output.pdf \
  --print-to-pdf-no-header \
  "file:///path/to/input.html" 2>/dev/null
```

---

### 8. README erstellen

`repairs/ORDNERNAME/README.md`:

```markdown
# KOMPONENTE — MODELL (BAUJAHR)

**DTC:** [falls bekannt aus fehler_verlauf.md]
**Priorität:** [Hoch/Mittel/Niedrig + Begründung]

---

## Vorbereitungen (falls nötig)
[Referenzierte Unterprozeduren aus VIDA — z.B. "Scheibenwischer entfernen"]
→ [Link zu Unterprozedur-PDF]

---

## Hauptschritte
[Aus VIDA-Dokument: Ausbau, Einbau]

---

## Teile & Werkzeug
→ [teile_werkzeug.md](teile_werkzeug.md)

---

## Fehleranalyse
→ [fehleranalyse.md](fehleranalyse.md) [falls vorhanden]

---

## PDFs aus VIDA
- [hauptanleitung.pdf](pdfs/...) — VCC-XXXXXX-X: Titel
- [vorbereitung.pdf](pdfs/...) — VCC-XXXXXX-X: Vorbereitung

**Bilder:** [Liste der GIF-Dateien mit Quelle imagerepository]

_Extrahiert aus VIDA-DB servicerep_$VIDA_LANGUAGE, [Datum]. Fahrzeug: YOUR_VIN_HERE_

---

## Quellenangaben

Alle Angaben in dieser Reparaturmappe stammen ausschließlich aus:

| Angabe | Quelle |
|--------|--------|
| [Drehmomentwert] | VCC-XXXXXX-X (extrahiert [Datum]) |
| [Teilenummer] | VCC-XXXXXX-X |
| [Pin-Belegung] | VCC-XXXXXX-X oder `facts/vehicle_facts.md` |

**Nicht aus VIDA verfügbar:** _(falls leer: alle Angaben belegt)_
```

---

### 9. Reparatur-Log aktualisieren

**Immer nach `/vida_repair` ausführen** — `repairs/reparatur_log.md` aktualisieren:

1. **Übersichtstabelle:** Neue Zeile eintragen (Nummer, Komponente, DTC, Dringlichkeit, Status, Link zur Anleitung)
2. **Details-Abschnitt:** Neuen Abschnitt `### N — KOMPONENTE` anlegen mit:
   - Befund (aus fehleranalyse.md)
   - Kosten (geschätzt)
   - Todo-Checkboxen (konkrete nächste Schritte)
   - Links zu README.md und fehleranalyse.md
3. **Geistercodes-Tabelle:** Falls der DTC dort gelistet ist, Eintrag mit Link zur Reparaturmappe ergänzen
4. **Abhängigkeiten:** Falls die neue Komponente andere Einträge beeinflusst, diese Einträge ebenfalls aktualisieren
5. **Datum** im Header aktualisieren

---

### 10. Commit und Push

```bash
git -C "$REPO" add repairs/ORDNERNAME/
git -C "$REPO" add repairs/reparatur_log.md
git -C "$REPO" commit -m "Add repair: KOMPONENTE — VIDA-Daten extrahiert"
git -C "$REPO" push
$SSH_CMD "git -C $REMOTE_REPO_PATH pull"
```

---

## Technische Details (für alle Schritte)

**SSH zum Host (via config.sh):**
```bash
$SSH_CMD
```

**VM-Tastatureingabe:**
```bash
# Befehl in CMD eingeben:
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputstring 'BEFEHL'"
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputscancode 1c 9c"  # Enter

# Win+R für neues CMD-Fenster:
$SSH_CMD "vboxmanage controlvm '$VM_NAME' keyboardputscancode e0 5b 13 93 e0 db"
```

**Z:\ = $REMOTE_DOWNLOADS_PATH auf dem Host** — shared folder für Datenaustausch.

**Shared Folder prüfen** (falls Z:\ nicht erreichbar):
```bash
$SSH_CMD "vboxmanage showvminfo '$VM_NAME' | grep -i shared"
# Falls leer:
$SSH_CMD "vboxmanage sharedfolder add '$VM_NAME' --name vida_share --hostpath $REMOTE_DOWNLOADS_PATH --transient"
# Dann in CMD: net use Z: \\vboxsvr\vida_share
```

**ZIP-Decode für XmlContent:**
- XmlContent = `image` Typ in SQL = ZIP-komprimiertes XML
- Inhalt ist eine einzelne .xml Datei (z.B. `0900c8af8085831a_de-DE.xml`) — Sprach-Suffix entspricht `$VIDA_LANGUAGE`
- Bilder werden als `0900c8af[8hex]_0_0.gif` referenziert

**BCP-Bildexport:**
- BCP exportiert mit 4-Byte-Prefix → reales Bild-Bytes ab Offset 4
- Erkennbar: wenn `data[4:7] == b'GIF'` → 4 Bytes abschneiden
- Befehl: `bcp "SELECT TOP 1 imageData FROM imagerepository.dbo.LocalizedGraphics WHERE fkGraphic='ID' ORDER BY DATALENGTH(imageData) DESC" queryout Z:\img.gif -S .\VIDA -T -n`

**Immer Timestamp der Output-Dateien prüfen** (stale Daten vermeiden):
```bash
$SSH_CMD "stat ~/Downloads/DATEI.txt"
```

---

## Abschlusskontrolle

Am Ende:
- [ ] Alle PDFs existieren und haben Inhalt (> 50KB)
- [ ] Bilder sind valide GIFs (magic bytes GIF89a)
- [ ] README vollständig (DTC, Vorbereitungen, Schritte, Teile)
- [ ] teile_werkzeug.md existiert
- [ ] fehleranalyse.md existiert (falls DTC bekannt)
- [ ] Git push erfolgreich, Host pull erfolgreich
- [ ] Ausgabe: kurze Zusammenfassung was erstellt wurde
