# CLAUDE.md — volvo-vida-claude

## Projekt-Kontext

Dieses Projekt steuert eine VIDA 2014D-Installation (Windows 7 VM in VirtualBox) auf einem Linux-Rechner per Claude Code. Es ermöglicht vollautomatische Diagnose-Readouts, Reparaturmappen aus der VIDA-Datenbank, und Verwaltung von Reparatur-Dokumentation.

## Konfiguration

Alle Verbindungsdaten und Pfade stehen in `scripts/config.sh` (vom User angelegt, nicht im Git).  
Template: `scripts/config.sh.example`

**Immer zuerst:** `source scripts/config.sh` um die Variablen zu laden.

## Slash Commands

| Command | Was |
|---------|-----|
| `/vida_start` | VIDA VM starten + RDP öffnen |
| `/vida_stop` | VIDA VM sauber herunterfahren |
| `/vida_status` | VM-Zustand + Host RAM/Disk |
| `/vida_screenshot` | Screenshot der laufenden VM |
| `/vida_readout` | Vollständiger Diagnose-Readout aus SQL |
| `/vida_repair <komponente>` | Reparaturmappe aus VIDA-DB erstellen |
| `/vida_xps2pdf` | VIDA-Druckdokumente (XPS → PDF) |
| `/repair_done <ordner> <name>` | Reparatur als erledigt markieren |

## Wichtige Pfade

- Konfiguration: `scripts/config.sh`
- VIDA-Readouts: `readouts/vida/`
- Fehlerverlauf: `readouts/fehler_verlauf.md`
- Reparaturen: `repairs/`
- Reparatur-Log: `repairs/reparatur_log.md`
- PDF-Archiv: `readouts/pdfs/`

## Repo-Pfad ermitteln

In allen Bash-Blöcken:
```bash
REPO=$(git rev-parse --show-toplevel)
```

## Arbeitsregeln

- Alle SSH-Befehle verwenden Variablen aus `scripts/config.sh` — keine hardcoded Werte
- Vor VirtualBox-Befehlen: immer VM-Reachability prüfen
- Nach jedem Readout oder neuer Reparaturmappe: `git push` + Host `git pull`
- Keine destructiven Aktionen ohne Bestätigung (VM löschen, Netzwerk-Config ändern)
