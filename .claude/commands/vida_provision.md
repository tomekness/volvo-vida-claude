Richtet eine neue VIDA VM ein — oder prüft und vervollständigt ein bestehendes Setup.
Lese zuerst `docs/SETUP_VM.md` für die vollständige Anleitung.

Arbeite die Schritte der Reihe nach ab. Bei jedem Schritt: Zustand prüfen, nur ausführen
wenn noch nicht erledigt. Bei destructiven Aktionen (VM importieren, Netzwerk konfigurieren)
immer den User um Bestätigung bitten.

---

## Schritt 1: config.sh anlegen (falls fehlt)

```bash
REPO=$(git rev-parse --show-toplevel)
ls $REPO/scripts/config.sh 2>/dev/null || echo "FEHLT"
```

Falls fehlt: aus Template kopieren und User bitten, die Werte einzutragen:
```bash
cp $REPO/scripts/config.sh.example $REPO/scripts/config.sh
```

Dann `scripts/config.sh` öffnen — gemeinsam mit dem User folgende Werte festlegen:
- `AGENT_MODE` — "local" (VIDA auf diesem Rechner) oder "ssh" (Remote-Host)
- `VM_NAME` — exakter Name der VM wie in VirtualBox angezeigt
- `RDP_HOST` — für local mode: "localhost:3389"
- `SSH_*` — nur bei AGENT_MODE=ssh

## Schritt 2: Voraussetzungen prüfen

```bash
source $REPO/scripts/config.sh
source $REPO/scripts/lib.sh

# VirtualBox
run_cmd "VBoxManage --version" && echo "VirtualBox OK" || echo "FEHLT: VirtualBox"
# Python 3
python3 --version && echo "Python3 OK" || echo "FEHLT: python3"
# RDP-Client (lokal — für vida_start)
(command -v remmina || command -v xfreerdp) && echo "RDP OK" || echo "FEHLT: remmina oder xfreerdp"
```

Bei AGENT_MODE=ssh zusätzlich: SSH-Erreichbarkeit prüfen:
```bash
run_cmd "echo 'SSH OK'"
```

## Schritt 3: VM existiert bereits?

```bash
run_cmd "VBoxManage list vms | grep -i vida"
```

Falls die VM nicht gefunden wird → Schritt 4 (VM importieren).
Falls gefunden → Schritt 5 (VM konfigurieren prüfen).

## Schritt 4: VM importieren (OVA)

VIDA VMs (als OVA) sind bei volvodiag.com verfügbar — diese Anleitung enthält keine
VIDA-Software selbst.

User fragen: "Wo liegt die OVA-Datei?" (Pfad auf dem Host-Rechner / lokal).
Dann — nach Bestätigung des Users:

```bash
# OVA_PATH = vom User angegebener Pfad
run_cmd "VBoxManage import '$OVA_PATH' --vsys 0 --vmname '$VM_NAME'"
```

Importdauer: ca. 2–10 Minuten je nach Dateigröße.

## Schritt 5: Shared Folder konfigurieren

Prüfen ob Shared Folder "SharedDownloads" schon existiert:
```bash
run_cmd "VBoxManage showvminfo '$VM_NAME' | grep -i shared"
```

Falls nicht vorhanden — nach Bestätigung:
```bash
# Im Local-Mode: REMOTE_DOWNLOADS_PATH ist ~/Downloads auf diesem Rechner
DOWNLOADS_PATH=$(run_cmd "echo $REMOTE_DOWNLOADS_PATH" 2>/dev/null || echo "$HOME/Downloads")
run_cmd "VBoxManage sharedfolder add '$VM_NAME' --name 'SharedDownloads' --hostpath '$DOWNLOADS_PATH' --automount"
```

## Schritt 6: NAT-Ports konfigurieren

Prüfen ob Ports schon weitergeleitet werden:
```bash
run_cmd "VBoxManage showvminfo '$VM_NAME' | grep -E 'NIC|Rule'"
```

Falls SQL-Port 14333 fehlt — nach Bestätigung:
```bash
run_cmd "VBoxManage modifyvm '$VM_NAME' --natpf1 'vida-sql,tcp,,${SQL_PORT_NAT:-14333},,1433'"
```

VRDE (RDP) prüfen:
```bash
run_cmd "VBoxManage modifyvm '$VM_NAME' --vrde on --vrdeport 3389"
```

## Schritt 7: VM starten und testen

```bash
$REPO/scripts/vida_start
```

Warte ~90 Sekunden, dann Status prüfen:
```bash
$REPO/scripts/vida_status
```

Screenshot machen um zu sehen was auf dem Desktop ist:
```bash
$REPO/scripts/vida_screenshot
```

## Schritt 8: Sprache umstellen (optional)

Den User fragen ob die VIDA-Sprache umgestellt werden soll.
Falls ja: Anleitung aus `docs/SETUP_VM.md` → Abschnitt "Sprache umstellen" folgen.
Dazu RDP-Verbindung öffnen und den Language Switcher auf dem Windows-Desktop nutzen.

## Schritt 9: Baseline-Snapshot erstellen

Nach erfolgreichem Setup:
```bash
$REPO/scripts/vida_snapshot "baseline-setup"
```

Dann in `scripts/config.sh` eintragen:
```bash
DEFAULT_SNAPSHOT="baseline-setup"
```

## Fertig

```bash
$REPO/scripts/vida_status
```

Setup abgeschlossen wenn VM läuft und Status OK meldet.
Nächster Schritt: `/vida_init <fahrzeug>` — Fahrzeugprojekt anlegen.
