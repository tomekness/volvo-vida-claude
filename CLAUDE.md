# CLAUDE.md — volvo-vida-claude

## Projekt-Kontext

Dieses Projekt steuert eine VIDA 2014D-Installation (Windows 7 VM in VirtualBox) auf einem Linux-Rechner per Claude Code. Es ermöglicht vollautomatische Diagnose-Readouts, Reparaturmappen aus der VIDA-Datenbank, und Verwaltung von Reparatur-Dokumentation.

## Konfiguration

Alle Verbindungsdaten und Pfade stehen in `scripts/config.sh` (vom User angelegt, nicht im Git).  
Template: `scripts/config.sh.example`

**Immer zuerst:** `source scripts/config.sh` um die Variablen zu laden.

**AGENT_MODE:** `"local"` = VIDA und Agent laufen auf demselben Rechner (kein SSH).  
`"ssh"` = VIDA läuft auf einem Remote-Host (Standard). Alle Scripts unterstützen beide Modi.

## Slash Commands

| Command | Was |
|---------|-----|
| `/vida_provision` | **VM einrichten** — Ersteinrichtung oder Setup vervollständigen |
| `/vida_init <fahrzeug>` | **Neues Fahrzeugprojekt anlegen** — VIDA-IDs ermitteln, `facts/vehicle_facts.md` erstellen |
| `/vida_start` | VIDA VM starten + RDP öffnen |
| `/vida_stop` | VIDA VM sauber herunterfahren |
| `/vida_status` | VM-Zustand + Host RAM/Disk |
| `/vida_screenshot` | Screenshot der laufenden VM |
| `/vida_snapshot [name]` | Snapshot nehmen, auflisten oder löschen |
| `/vida_reset [snapshot]` | VM auf Snapshot zurücksetzen (default: `DEFAULT_SNAPSHOT` aus config.sh) |
| `/vida_readout` | Vollständiger Diagnose-Readout aus SQL |
| `/vida_repair <komponente>` | Reparaturmappe aus VIDA-DB erstellen |
| `/vida_xps2pdf` | VIDA-Druckdokumente (XPS → PDF) |
| `/vida_debug` | Einen offenen Debug-Task aus `vida_debug/TODO.md` ausführen |
| `/repair_done <ordner> <name>` | Reparatur als erledigt markieren |
| `/host_sync` | Host-Rechner bidirektional mit Repo synchronisieren |

## Wichtige Pfade

- Konfiguration: `scripts/config.sh`
- Fahrzeugdaten: `facts/vehicle_facts.md` — **Einzige Quelle der Wahrheit** für alle verifizierten Spezifika
- VIDA-Readouts: `readouts/vida/YYYY-MM-DD/` (Scan-Dateien, Rohdaten, `printouts/`, `screenshots/`)
- Fehlerverlauf: `readouts/fehler_verlauf.md`
- Reparaturen: `repairs/`
- Reparatur-Log: `repairs/reparatur_log.md`

## Repo-Pfad ermitteln

In allen Bash-Blöcken:
```bash
REPO=$(git rev-parse --show-toplevel)
```

## VIDA Web UI (Chrome DevTools MCP)

SSH-Tunnel öffnen: `scripts/vida_connect`  
URL danach: `http://localhost:${VIDA_LOCAL_PORT}/Vida`  
Login: Username `admin`, kein Passwort (nicht `vida` oder `administrator`!)  
**Wichtig: VIDA erlaubt nur eine gleichzeitige Session.** Wenn IE in VM eingeloggt ist, wird die Browser-Session automatisch ausgeloggt — immer nur eine aktive Session nutzen.

## Sprache umstellen

Auf dem Windows-Desktop der VM liegt der Ordner **"Language Switcher"** mit Sprach-Installern.  
Installer-Passwort (bei VMs von volvodiag.com): `volvodiag.com`

Ablauf via RDP (`remmina rdp://$RDP_HOST`):
1. Doppelklick auf `V2DLS-German.exe` (oder gewünschte Sprache)
2. Lizenz akzeptieren → Passwort `volvodiag.com` eingeben
3. VIDA neu starten

Danach: Snapshot empfohlen (`vida_reset --list` für Übersicht).

## Datenqualität — Quellenverantwortung

Bei jeder elektrotechnischen Frage (Pins, Farben, Spannungen, Steckerbelegungen):

1. `facts/vehicle_facts.md` lesen — hier stehen alle verifizierten Fahrzeugdaten mit Quelle
2. `repairs/KOMPONENTE/` lesen — bestehende Reparaturmappen können mehr Details enthalten
3. Erst danach VIDA SQL abfragen

**Jede Angabe braucht eine Quellenspalte** — VCC-Nummer oder bestätigte Messung mit Datum.  
**Fehlende Quelle = Angabe weglassen.** Niemals aus Trainingsdaten ergänzen.

## Arbeitsregeln

- Alle SSH-Befehle verwenden Variablen aus `scripts/config.sh` — keine hardcoded Werte
- Vor VirtualBox-Befehlen: immer VM-Reachability prüfen
- Nach jedem Readout oder neuer Reparaturmappe: `git push` + Host `git pull`
- Keine destructiven Aktionen ohne Bestätigung (VM löschen, Netzwerk-Config ändern)
