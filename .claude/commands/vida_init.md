Initialisiert ein neues VIDA-Diagnoseprojekt für ein Fahrzeug.

## Argument

`$ARGUMENTS` = Fahrzeugbeschreibung (z.B. "Volvo XC70 2004 B5254T2" oder "V70 2001 2.4T")

---

## Zweck

Legt die komplette Projektstruktur an, fragt VIDA nach den Fahrzeug-IDs und erstellt `facts/vehicle_facts.md` als verifizierten Datenankerpunkt. Muss einmalig pro Fahrzeugprojekt ausgeführt werden.

---

## Schritt 1 — Verzeichnisstruktur anlegen

```bash
REPO=$(git rev-parse --show-toplevel)
mkdir -p "$REPO/facts"
mkdir -p "$REPO/readouts/vida"
mkdir -p "$REPO/repairs/_done"
```

---

## Schritt 2 — VIN und Fahrzeugdaten vom User erfragen

Falls nicht in `$ARGUMENTS` angegeben, direkt fragen:
- VIN (17-stellig)
- Modell + Baujahr (z.B. "V70 II, 2002")
- Motorcode (z.B. "B5244S2")
- SSH-Zugang zum Diagnose-Rechner (`SSH_HOST`, `SSH_PORT`, `SSH_USER`)

---

## Schritt 3 — VIDA-Fahrzeug-IDs ermitteln

VM muss laufen. SSH-Zugang aus `scripts/config.sh` oder direkt angegeben.

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
SSH_CMD="ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST"
```

**3a — Alle Fahrzeugmodelle in VIDA auflisten:**
```
sqlcmd -S .\VIDA -d vida -Q "SELECT Id, Name FROM VehicleModel ORDER BY Name" -o Z:\vehicle_models.txt -y 0
```

**3b — Passenden Eintrag für das Fahrzeug identifizieren** (z.B. "V70" → fkVehicleModel = ?)

**3c — Modelljahre für dieses Modell auflisten:**
```
sqlcmd -S .\VIDA -d vida -Q "SELECT Id, Name FROM ModelYear WHERE fkVehicleModel = MODELL_ID ORDER BY Name" -o Z:\model_years.txt -y 0
```

**3d — Passenden Eintrag für das Baujahr identifizieren** (z.B. "2002" → fkModelYear = ?)

**3e — Verifikation mit DocumentProfile:**
```
sqlcmd -S .\VIDA -d servicerep_de-DE -Q "SELECT COUNT(*) as AnzahlDokumente FROM DocumentProfile dp WHERE dp.fkVehicleModel = MODELL_ID AND dp.fkModelYear = JAHR_ID" -o Z:\doc_count.txt -y 0
```

Mindestens > 100 Dokumente sollten gefunden werden. Falls 0: IDs nochmal prüfen.

---

## Schritt 4 — `scripts/config.sh` anlegen / aktualisieren

Kopiere `scripts/config.sh.example` nach `scripts/config.sh` und passe an:

```bash
cp scripts/config.sh.example scripts/config.sh
```

Wichtige Felder für dieses Projekt:
```bash
SSH_HOST="IP_ODER_HOSTNAME"
SSH_PORT="22"
SSH_USER="username"
SSH_KEY="$HOME/.ssh/id_ed25519"
VM_NAME="VIDA 2014D"
RDP_HOST="IP_ODER_HOSTNAME:3389"
REMOTE_REPO_PATH="$HOST_DESKTOP/REPO_NAME"
REMOTE_DOWNLOADS_PATH="$HOST_DOWNLOADS"
VIN="YOUR_VIN_HERE"
VIDA_VEHICLE_MODEL="MODELL_ID"    # aus Schritt 3b
VIDA_MODEL_YEAR="JAHR_ID"         # aus Schritt 3d

# vida_docs.db — 230 MB SQLite, nicht im Git
# 0 = auf SSH-Host (Diagnose-Rechner), 1 = lokal auf diesem Rechner
VIDA_DOCS_LOCAL=0
VIDA_DOCS_DB_PATH="$HOST_DESKTOP/vida_docs.db"
```

**vida_docs.db einrichten:** Die DB ist fahrzeugunabhängig — einmal pro Diagnose-Rechner, nicht pro Projekt.

- Wenn sie noch nicht existiert: aus der VIDA-VM exportieren oder von einem anderen Rechner kopieren.
- Pfad in `VIDA_DOCS_DB_PATH` anpassen falls abweichend.
- Für lokale Nutzung auf diesem Rechner: `VIDA_DOCS_LOCAL=1` setzen und DB einmalig per SCP holen:
  ```bash
  scp -i $SSH_KEY -P $SSH_PORT $SSH_USER@$SSH_HOST:$VIDA_DOCS_DB_PATH ./vida_docs.db
  # Dann VIDA_DOCS_DB_PATH auf lokalen Pfad setzen, z.B.:
  # VIDA_DOCS_DB_PATH="$HOME/.vida/vida_docs.db"
  ```

---

## Schritt 5 — Motorspezifika aus VIDA holen

**Fahrzeugdaten aus VIDA carcom-Datenbank:**
```
sqlcmd -S .\VIDA -d vida -Q "SELECT TOP 20 * FROM Vehicle WHERE VIN LIKE '%LETZTEN8STELLEN%'" -o Z:\vin_lookup.txt -y 0
```

Falls VIN in VIDA gefunden: Motorcode, Getriebe, Ausstattungsvariante aus VIDA übernehmen.  
Falls nicht: Daten aus Fahrzeugschein + User-Angabe übernehmen und als Quelle dokumentieren.

---

## Schritt 6 — `facts/vehicle_facts.md` erstellen

Neue Datei mit verifizierter Basis-Struktur anlegen:

```markdown
# Vehicle Facts — MODELL (BAUJAHR, MOTORCODE)

**Zweck:** Einzige Quelle der Wahrheit für alle verifizierten Fahrzeug-Spezifika.
Jede Angabe trägt eine Quellenspalte. Fehlende Quelle = Angabe nicht verwenden.

---

## Fahrzeugidentifikation

| Feld | Wert | Quelle |
|------|------|--------|
| VIN | YOUR_VIN_HERE | Fahrzeugschein |
| Modell | MODELL (PLATTFORM) | VIDA fkVehicleModel=MODELL_ID |
| Baujahr | BAUJAHR | VIDA fkModelYear=JAHR_ID |
| Motor | MOTORCODE | VIDA carcom / Fahrzeugschein |
| km-Stand (Referenz) | — km | (bei erstem Readout eintragen) |

---

## VIDA DocumentProfile — Fahrzeugfilter

| Parameter | Wert |
|-----------|------|
| fkVehicleModel | MODELL_ID |
| fkModelYear | JAHR_ID |

---

## Bestätigte VIDA-Quelldokumente

_(leer — wird mit jedem /vida_repair befüllt)_

| VCC-Nummer | Titel | Thema | Extrahiert |
|-----------|-------|-------|-----------|

---

## Was NICHT in VIDA gefunden wurde

_(leer — wird befüllt wenn eine Suche keinen Treffer liefert)_

| Angabe | Gesucht am | Suche |
|--------|-----------|-------|

---

_Letzte Aktualisierung: DATUM — Fahrzeug: YOUR_VIN_HERE_
```

---

## Schritt 7 — `CLAUDE.md` und `README.md` anpassen

**CLAUDE.md**: VIN, Modell, Motorcode im Projekt-Kontext eintragen.

**README.md**: Fahrzeugdaten, Diagnose-Rechner IP, ersten Statusabschnitt befüllen.

---

## Schritt 8 — Erster Test-Readout (optional aber empfohlen)

```bash
/vida_readout
```

Bestätigt dass VIDA + SQL funktioniert und liefert erste echte DTCs und Freeze-Frame-Daten für `readouts/vida/DATUM/`.

---

## Schritt 9 — Commit

```bash
git add facts/ repairs/ readouts/ scripts/config.sh CLAUDE.md README.md
git commit -m "Init: MODELL BAUJAHR — VIDA-Projekt angelegt, vehicle_facts.md erstellt"
git push
```

---

## Checkliste am Ende

- [ ] `facts/vehicle_facts.md` existiert mit VIN, Modell, VIDA-IDs
- [ ] `scripts/config.sh` enthält korrekte fkVehicleModel und fkModelYear
- [ ] DocumentProfile-Verifikation ergab > 100 Dokumente
- [ ] `README.md` enthält Fahrzeugdaten und Diagnose-Rechner-Zugang
- [ ] `CLAUDE.md` enthält Fahrzeugdaten
- [ ] Git-Push erfolgreich

---

## Hinweis für neue Fahrzeuge (anderes Modell/Baujahr)

VIDA 2014D deckt alle Volvo-Modelle von ca. 1990–2014 ab. Die VIDA-IDs (fkVehicleModel, fkModelYear) unterscheiden sich je nach Modell. Schritt 3 ermittelt diese Werte zuverlässig direkt aus der VIDA-Datenbank — niemals raten oder von einem anderen Fahrzeug übernehmen.

Für Fahrzeuge nach 2014: VIDA 2014D hat möglicherweise keine oder unvollständige Dokumente. VIDA AllInOne (neuere Version) prüfen.
