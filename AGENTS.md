# AGENTS.md — volvo-vida-claude

Instruktionen für KI-Assistenten (Codex, Gemini, etc.) — ergänzt `CLAUDE.md`.

## Projekt-Kontext

Dieses Projekt steuert eine VIDA 2014D-Installation (Windows 7 VM in VirtualBox) auf einem Linux-Rechner. Es ermöglicht automatische Diagnose-Readouts, Reparaturmappen aus der VIDA-Datenbank und Verwaltung von Reparatur-Dokumentation für Volvo-Fahrzeuge.

## Konfiguration

Alle Verbindungsdaten und Pfade stehen in `scripts/config.sh` (nicht im Git).  
Template: `scripts/config.sh.example`

Repo-Root immer per:
```bash
REPO=$(git rev-parse --show-toplevel)
```

## Datenqualität

**Bei elektrotechnischen Fragen** (Pins, Farben, Spannungen, Steckerbelegungen):
1. `facts/vehicle_facts.md` — einzige Quelle der Wahrheit für verifizierte Fahrzeugdaten
2. `repairs/KOMPONENTE/` — bestehende Reparaturmappen
3. Erst danach VIDA SQL abfragen

**Bei DTC-Auswertung** (Freeze Frame, Status Identifier, FaultCounter):
1. `facts/vida_dtc_definitionen.md` — Definitionen für SI 1–9, FC1/3/4
2. `"Echtzeit seit Zurücksetzen: 0 s"` ≠ "sofort nach Code-Löschung"
3. SI 6 prüfen: Nein = Test läuft frei, Ja = Test gehemmt
4. Niemals nur einen einzelnen Readout bewerten — immer alle Logs/Werte des Tages und Verlaufsdaten aus `readouts/fehler_verlauf.md`, `readouts/`, `repairs/` heranziehen

**Jede Angabe braucht eine Quellenspalte** — VCC-Nummer oder bestätigte Messung mit Datum.  
**Fehlende Quelle = Angabe weglassen.** Niemals aus Trainingsdaten ergänzen.

## Arbeitsregeln

- Keine hardcoded Pfade oder IP-Adressen — alles über `scripts/config.sh`
- Vor VirtualBox-Befehlen: VM-Reachability prüfen
- Nach Readout oder neuer Reparaturmappe: `git push` + Host `git pull`
- Keine destructiven Aktionen ohne Bestätigung (VM löschen, Netzwerk-Config ändern)

## Wichtige Pfade

| Pfad | Inhalt |
|------|--------|
| `facts/vehicle_facts.md` | Verifizierte Fahrzeugdaten mit Quellenangabe |
| `facts/vida_dtc_definitionen.md` | DTC-Definitionen, SI- und FC-Erklärungen |
| `readouts/vida/YYYY-MM-DD/` | Scan-Dateien, Rohdaten, Printouts, Screenshots |
| `readouts/fehler_verlauf.md` | Fehlerverlauf über alle Sessions |
| `repairs/` | Reparaturmappen pro Komponente |
| `repairs/reparatur_log.md` | Reparatur-Log |
| `scripts/config.sh` | Lokale Konfiguration (nicht im Git) |
