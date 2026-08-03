Erstelle eine vollständige Reparaturmappe für eine Fahrzeugkomponente aus VIDA-Daten.

## Argument

`$ARGUMENTS` = Name der Komponente (z.B. "scheibenwischer", "lambda sonde vorne", "scheinwerfer vorne")

Daraus:
- Ordnername: Kleinbuchstaben, Leerzeichen → Unterstrich (z.B. `lambda_sonde_vorne`)
- Suchbegriffe für VIDA-DB (mehrere Varianten)

## Konfiguration laden

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
SSH_CMD="ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST"
```

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

Sende per CMD in der VM (CMD muss offen sein — ggf. Win+R → cmd, Scancode `e0 5b 13 93 e0 db`):

```
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT vccNumber, title, path FROM Document WHERE title LIKE '%SUCHBEGRIFF%' ORDER BY vccNumber" -o Z:\repair_search.txt -y 0
```

Ausgabe lesen:
```bash
$SSH_CMD "cat $REMOTE_DOWNLOADS_PATH/repair_search.txt"
```

**Relevante Docs auswählen** (Priorität):
1. "auswechseln" / "ersetzen" / "ausbauen" → Hauptanleitung
2. "überprüfen" / "prüfen" / "diagnose" → Diagnoseanleitung
3. Bauteilname ohne Verb → Technische Info

**Fahrzeugspezifische Filterung via DocumentProfile:**
```
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT DISTINCT d.vccNumber, d.title FROM Document d JOIN DocumentProfile dp ON dp.fkDocument = d.Id WHERE d.title LIKE '%SUCHBEGRIFF%' AND dp.fkVehicleModel = VIDA_VEHICLE_MODEL_PLACEHOLDER AND dp.fkModelYear = VIDA_MODEL_YEAR_PLACEHOLDER ORDER BY d.vccNumber" -o Z:\repair_search_filtered.txt -y 0
```

Ersetze `VIDA_VEHICLE_MODEL_PLACEHOLDER` mit `$VIDA_VEHICLE_MODEL` und `VIDA_MODEL_YEAR_PLACEHOLDER` mit `$VIDA_MODEL_YEAR` aus der Konfiguration.

Falls gefilterte Suche zu wenig Treffer: ungefilterte Suche als Fallback.

---

### 2. XML-Inhalt extrahieren (ZIP-Decode)

Für jedes ausgewählte Dokument:

```
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT CONVERT(varchar(max), CONVERT(varbinary(max), XmlContent), 1) FROM Document WHERE vccNumber='VCC-XXXXXX-X'" -o Z:\doc_VCCXXXXXX.txt -y 0
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
        return None, [], []
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

**Aus dem Text identifizieren:**
- Einbauhinweise / nummerierte Schritte
- Teilenummern (z.B. "Bestellnr. 1161035-9")
- Drehmomente (z.B. "55 Nm")
- Werkzeuge (z.B. "Lambda-Schlüssel 22mm")
- Referenzen auf andere Dokumente (`de-DE0900c8af...`)

---

### 3. Referenzierte Unterprozeduren holen

Für jede Referenz-ID (`0900c8af...`):
```
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT vccNumber, title, path FROM Document WHERE path LIKE '%0900c8afXXXXXXXX%'" -o Z:\ref_search.txt -y 0
```

Falls Treffer: XML wie in Schritt 2 extrahieren. Diese Dokumente kommen in den **Vorbereitungen**-Abschnitt der README.

---

### 4. Bilder extrahieren

Für jede Bild-ID (`0900c8af...`):
```
bcp "SELECT TOP 1 imageData FROM imagerepository.dbo.LocalizedGraphics WHERE fkGraphic = '0900c8afXXXXXXXX' ORDER BY DATALENGTH(imageData) DESC" queryout Z:\imgXXXXXXXX.gif -S .\VIDA -T -n
```

4-Byte BCP-Prefix entfernen:
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

Per SCP in `repairs/ORDNERNAME/pdfs/` kopieren.

---

### 5. Teileliste und Werkzeuge

`repairs/ORDNERNAME/teile_werkzeug.md` erstellen:

```markdown
# Teile & Werkzeug — KOMPONENTE

## Benötigte Teile

| Teil | Volvo Bestellnr. | Beschreibung |
|------|-----------------|-------------|

## Werkzeuge

| Werkzeug | Spezifikation |
|----------|--------------|

## Drehmomente

| Bauteil | Drehmoment |
|---------|-----------|

## Hinweise
```

---

### 6. Fehleranalyse (falls bekannter DTC)

```bash
grep -ri "KOMPONENTENNAME\|DTCCODE" "$REPO/readouts/"
```

Falls Treffer: `repairs/ORDNERNAME/fehleranalyse.md` erstellen:

```markdown
# Fehleranalyse — KOMPONENTE

## Bekannte DTCs

| Code | ECU | Beschreibung | Erstmals | Status |
|------|-----|-------------|----------|--------|

## Freeze Frame Analyse

## Bewertung

## Empfehlung
```

---

### 7. PDFs erstellen

HTML mit VIDA-Quellenangabe, eingebetteten Bildern und Schritt-Anleitung erstellen:

```bash
google-chrome --headless --disable-gpu --no-sandbox \
  --print-to-pdf="$REPO/repairs/ORDNERNAME/pdfs/NAME.pdf" \
  --print-to-pdf-no-header \
  "file:///pfad/zur/input.html" 2>/dev/null
```

---

### 8. README erstellen

`repairs/ORDNERNAME/README.md`:

```markdown
# KOMPONENTE — [Fahrzeugmodell] ([Baujahr])

**DTC:** [falls bekannt]
**Priorität:** [Hoch/Mittel/Niedrig + Begründung]

---

## Vorbereitungen
[Referenzierte Unterprozeduren aus VIDA]

## Hauptschritte
[Aus VIDA-Dokument: Ausbau, Einbau]

## Teile & Werkzeug
→ [teile_werkzeug.md](teile_werkzeug.md)

## Fehleranalyse
→ [fehleranalyse.md](fehleranalyse.md)

## PDFs aus VIDA
- [hauptanleitung.pdf](pdfs/...) — VCC-XXXXXX-X: Titel

_Extrahiert aus VIDA-DB servicerep_de-DE, [Datum]. Fahrzeug: $VIN_
```

---

### 9. Reparatur-Log aktualisieren

`repairs/reparatur_log.md` aktualisieren:

1. **Übersichtstabelle:** Neue Zeile (Nummer, Komponente, DTC, Dringlichkeit, Status, Link)
2. **Details-Abschnitt:** Block `### N — KOMPONENTE` anlegen (Befund, Kosten, Todos, Links)
3. **Datum** im Header aktualisieren

---

### 10. Commit und Push

```bash
git -C "$REPO" add "repairs/ORDNERNAME/"
git -C "$REPO" add repairs/reparatur_log.md
git -C "$REPO" commit -m "Add repair: KOMPONENTE — VIDA-Daten extrahiert"
git -C "$REPO" push
$SSH_CMD "git -C $REMOTE_REPO_PATH pull"
```

---

## Technische Details

**VM-Tastatureingabe:**
```bash
# Befehl in CMD eingeben:
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputstring "BEFEHL"'
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode 1c 9c'  # Enter

# Win+R für neues CMD-Fenster:
$SSH_CMD 'vboxmanage controlvm "'$VM_NAME'" keyboardputscancode e0 5b 13 93 e0 db'
```

**Z:\ = `$REMOTE_DOWNLOADS_PATH` auf dem Host** — Shared Folder für Datenaustausch.

**Shared Folder prüfen** (falls Z:\ nicht erreichbar):
```bash
$SSH_CMD "vboxmanage showvminfo '$VM_NAME' | grep -i shared"
# Falls leer:
$SSH_CMD "vboxmanage sharedfolder add '$VM_NAME' --name vida_share --hostpath $REMOTE_DOWNLOADS_PATH --transient"
# Dann in CMD: net use Z: \\vboxsvr\vida_share
```

**BCP-Bildexport:** 4-Byte-Prefix → reales Bild ab Offset 4. Erkennbar: `data[4:7] == b'GIF'`.

## Abschlusskontrolle

- [ ] Alle PDFs existieren und haben Inhalt (> 50KB)
- [ ] Bilder sind valide GIFs (magic bytes GIF89a)
- [ ] README vollständig (DTC, Vorbereitungen, Schritte, Teile)
- [ ] teile_werkzeug.md existiert
- [ ] fehleranalyse.md existiert (falls DTC bekannt)
- [ ] Git push erfolgreich, Host pull erfolgreich
