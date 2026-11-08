# Externe Referenz-Repos — Volvo VIDA Diagnostik

Ausgewertet 2026-11-07. Alle vier Repos befassen sich mit VIDA 2014D-Datenbank-Reverse-Engineering
oder direkter Fahrzeugdiagnostik ohne VIDA.

---

## 1. Tigo2000/Volvo-VIDA

**URL:** https://github.com/Tigo2000/Volvo-VIDA  
**Fokus:** SQL-Queries + PowerShell-Scripts für VIDA's interne MSSQL-Datenbank  
**Fahrzeug:** Volvo C30 T5 2008 (P1-Plattform)

### Was es kann

- SQL-Queries direkt gegen VIDA's MSSQL-Server (`sa / GunnarS3g3`)
- Vollständige Tabellen-Join-Ketten für ECU-Parameter, DTCs, Reparaturdokumente
- PowerShell-Batch-Export aller ECU-Parameter als CSV
- Python-Script zum Brute-Force aktiver CAN-Device-IDs
- `ECU-Commands.txt`: vollständige D2-Servicekommando-Liste (0xA1–0xBB)

### Key Files

| Datei | Inhalt |
|-------|--------|
| `SQL/Get-CANValuesUsingEcuId.sql` | Kern-Query: alle CAN-Parameter pro ECU (Join T100→T141→T150→T155→T191) |
| `SQL/Get-AllEcusForC30.sql` | Alle ECUs eines Vehicle-Profiles auflisten |
| `SQL/Get-VCCDocuments.sql` | Reparaturdokumente aus DB extrahieren (komprimiert als Hex) |
| `scripts/Get-ParametersForAllECUs.ps1` | Batch-Export aller ECU-Parameter als CSV |
| `scripts/bruteforce_can_device_ids.py` | CAN-Device-ID-Scan (python-can, Service 0xAE) |
| `ECU-Commands.txt` | D2-Dienst-Referenz: A6=REID, AE=DTC lesen, B9=Block lesen, … |

### VIDA CarCom Tabellen-Schema (T1xx)

```
T100_EcuVariant     — ECU-Varianten (EcuVariantIdentifier)
T141_Block          — Parameter-Blöcke (TextId, Offset, Länge in Bits)
T144_BlockChild     — Baum-Struktur: Blöcke per ECU-Variante
T150_BlockValue     — Einzelwerte (CompareValue als Hex-Identifier)
T155_Scaling        — Umrechnungsformeln (z.B. "x / 2", "x * 1 / 10.6")
T191_TextData       — Parameternamen + Einheiten (17 Sprachen)
T161_Profile        — Fahrzeug-Profile (Modell, Baujahr, Motor, Getriebe)
T160_DefaultEcuVariant — Verknüpft Profile mit ECU-Varianten
DiagSwdlRepository.ScriptContent — Diagnose-Scripts (komprimiert als Hex-XML)
```

> **Hinweis:** Diese T1xx-Tabellen gehören zur **CarCom-Datenbank** (ECU-Parameter, Live-Daten).
> Die `vida_docs.db` aus diesem Projekt nutzt ein anderes Schema (ServiceRepository, Reparaturdokumente).
> Siehe `scripts/vida_sql_queries/` für passende Queries.

### Use Cases

- SQL-Join-Muster für CarCom-Extraktion (wenn ECU-Parameter oder Live-Daten benötigt werden)
- `Get-VCCDocuments.sql`: zeigt wie VIDA-Dokumente aus der DB dekomprimiert werden
- CAN-Device-ID-Brute-Force: nützlich beim Erkunden unbekannter ECUs am CAN-Bus

---

## 2. spnda/volvo_vida_db

**URL:** https://github.com/spnda/volvo_vida_db  
**Fokus:** Modernes Python-Toolkit für VIDA-Datenbank (CSV-basiert, kein Live-MSSQL nötig)

### Was es kann

- Zwei-Phasen-Design: CSV-Export aus MSSQL (Windows) → Analyse überall mit Python + DuckDB
- VIN-Decoder: VIN → VIDA-Vehicle-Profile (Plattform, Motor, Getriebe, Karosserie)
- High-Level CLI: `ecus <VIN>`, `params "ECU_ID"`, `dtcs "ECU_ID"`, `text "keyword"`
- D2-Protokollimplementierung: Frame-Splitting, Reassembly, Request-Builder
- AST-basierter sicherer Evaluator für VIDA Scaling-Ausdrücke (kein `eval()`)

### Key Files

| Datei | Inhalt |
|-------|--------|
| `scripts/carcom.py` | ~800 Zeilen, High-Level-Interface für ECU-Blöcke, DTCs, Texte |
| `scripts/d2.py` | ~500 Zeilen, D2/CAN-Protokollimplementierung |
| `scripts/vin_decoder.py` | VIN → VIDA-Profile-Mapping, Plattform-Erkennung |
| `scripts/evaluate_conversion.py` | Sicherer Parser für VIDA Scaling-Ausdrücke |
| `sql/generate_csv.ps1` | VIDA MSSQL → CSV-Export (Voraussetzung für Python-Scripts) |

### Use Cases

- `vin_decoder.py`: VIN → VIDA-Profil auflösen (Modell, Motor, Plattform)
- `d2.py`: beste vorhandene D2/CAN-Protokoll-Implementierung — Vorlage für CAN-Erweiterung
- `carcom.py`-Muster: als Vorlage für Abstraktionsschicht über eigene SQLite-DB
- CSV-Export-Scripts: Ergänzung zu eigenem `extract.ps1` für CarCom-Daten

---

## 3. kForth/OpenVIDA

**URL:** https://github.com/kForth/OpenVIDA  
**Fokus:** Flask-Web-App als VIDA-Doku-Browser (Teile, Reparaturdokumente, Bilder)  
**Besonderheit:** Direkter Zugriff auf VIDA's SQL Server via `vida-py` ORM

### Was es kann

- Web-UI für Teile-Katalog (EPC), Reparaturdokumente, Schaltpläne
- VIN-basierte Fahrzeugprofilauflösung
- CGM (Computer Graphics Metafile) → SVG-Konvertierung on-the-fly für VIDA-Grafiken
- Caching: 24h TTL für statische Daten
- Benötigt laufende VIDA-Installation mit SQL Server

### Key Files

| Datei | Inhalt |
|-------|--------|
| `openvida/vida/api.py` | 200+ Zeilen Flask-API-Routen für alle VIDA-Datenbanken |
| `openvida/vida/basedata.py` | Vehicle-Profile, Modelljahr, Motor/Getriebe-Lookups |
| `openvida/vida/service.py` | Reparaturdokumente via vida-py ORM |
| `openvida/vida/epc.py` | Teile-Katalog-Navigation |
| `.env.example` | VIDA DB URIs: VIDA_BASEDATA_DB_URI, VIDA_DIAG_DB_URI, … |

### VIDA-Datenbanken (SQL Server Sessions)

```
BaseData          — Fahrzeugprofile, VINs, Modelljahre, Motoren, Getriebe
DiagSession       — Diagnose-Baum-Struktur
ServiceRepository — Reparaturdokumente, Qualifikatoren, Ressourcen
ImagesRepository  — Grafiken/Schaltpläne (CGM oder Raster)
```

### Use Cases

- Flask-API-Struktur aus `api.py`: Vorlage für eigene Reparaturdoku-Web-App
- CGM→SVG-Konvertierung: relevant wenn VIDA-Schaltpläne im Browser dargestellt werden sollen
- Caching-Pattern: übertragbar auf Flask-Stacks mit statischen Fahrzeugdaten
- `vida-py` ORM: Alternative zu direktem SQL für saubere Datenbankabstraktion

---

## 4. MarvinParanoid/VolvoDiagToolkit

**URL:** https://github.com/MarvinParanoid/VolvoDiagToolkit  
**Fokus:** Standalone-Fahrzeugdiagnose **ohne VIDA** — live CAN-Bus, YAML-Parameterdefinitionen  
**Fahrzeug:** Volvo V50 P1 (D4164T) — P2-Plattform noch nicht vorhanden

### Was es kann

- Live-Diagnose via J2534, SocketCAN oder ELM327
- YAML-Parameterdefinitionen pro Fahrzeugprofil (ECU-Adressen, Identifier, Skalierung)
- J2534-Proxy-DLL: loggt VIDA's CAN-Kommunikation transparent (Reverse-Engineering)
- Web-Dashboard + CLI: live monitor, DTC lesen/löschen, Fahrten aufzeichnen + analysieren
- CEM-Config-Backup + Diff (read-only)

### Key Files

| Datei | Inhalt |
|-------|--------|
| `python/volvo_diag/volvo/parameters.py` | Parameter-DB-Loader: Encoding, Parameter, EcuDefinition |
| `python/volvo_diag/volvo/ecm.py` | A6-Protokoll-Interpreter, REID/DTC-Reads |
| `python/volvo_diag/transport/elm_can.py` | ELM327-Transport (serielle CAN-Schnittstelle) |
| `proxy/src/j2534proxy.cpp` | Logging-DLL: Proxy zwischen VIDA und J2534-Treiber |
| `definitions/volvo/p1/vehicle.yaml` | Bus-Topologie-Template (500k HS, 125k LS, Modul-Adressen) |
| `docs/volvo-protocol.md` | Protokoll-Deep-Dive: A6, B9, B8, 0xAE, Multi-Frame |
| `docs/carcom.md` | Wie man Parameterdefinitionen aus VIDA's SQL extrahiert |

### YAML-Parameterformat (Beispiel)

```yaml
parameters:
  coolant_temperature:
    ecu: ECM
    protocol: volvo       # oder "uds"
    group: 0x11
    identifier: 0x0005    # On-Wire REID
    encoding: {type: uint16_be, scale: 0.1, offset: -273.14}
    unit: "degC"
    status: "verified-against-vida"
    source: "VIDA CarCom EcuVariant 486"
```

### Use Cases

- `elm_can.py`: Vorlage für ELM327-Erweiterung auf echtes CAN (statt OBD2-only)
- J2534-Proxy-DLL: wertvollstes Werkzeug zum Reverse-Engineeren fahrzeugspezifischer Parameter
- YAML-Format: Vorlage für eigene Fahrzeug-Parameterdefinitionen
- `docs/volvo-protocol.md`: Pflicht-Lektüre vor jeder CAN-Implementierung
- Neues Fahrzeugprofil anlegen: `definitions/volvo/p1/vehicle.yaml` als Template

---

## Zusammenfassung: Was wann nützlich ist

| Aufgabe | Repo | Konkrete Datei |
|---------|------|----------------|
| CarCom-DB Schema verstehen | Tigo2000 | `SQL/Get-CANValuesUsingEcuId.sql` |
| VIN → VIDA-Profil auflösen | spnda | `scripts/vin_decoder.py` |
| SQLite-Abstraktionsschicht | spnda | `scripts/carcom.py` (als Vorlage) |
| Flask-API für Reparaturdoku | OpenVIDA | `openvida/vida/api.py` |
| VIDA-Schaltpläne als SVG | OpenVIDA | CGM-Konvertierung in `api.py` |
| ELM327 → CAN erweitern | VolvoDiagToolkit | `transport/elm_can.py` + `d2.py` |
| Fahrzeugparameter reverse-engineeren | VolvoDiagToolkit | `proxy/src/j2534proxy.cpp` + `docs/volvo-protocol.md` |
| Vollständiger D2-Protokoll-Stack | spnda + VolvoDiagToolkit | `scripts/d2.py` |
