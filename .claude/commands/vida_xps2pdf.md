Scanne das VM-Austauschverzeichnis auf dem Host nach neuen XPS-Druckdokumenten aus VIDA, wandle sie in PDFs um und lege sie ins Repo.

## Konfiguration laden

```bash
REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"
SSH_CMD="ssh -i $SSH_KEY -p $SSH_PORT -o StrictHostKeyChecking=no $SSH_USER@$SSH_HOST"
```

## Ordner-Mapping (Quelle → Ziel im Repo)

| Download-Unterordner | Ziel im Repo |
|---|---|
| `auslesen/` | `readouts/pdfs/` |
| *(neu, unbekannt)* | `repairs/<ordnername>/pdfs/` |

Für unbekannte Unterordner: neuen Ordner in `repairs/` mit demselben Namen anlegen.

Repo-Pfade:
- Host: `$REMOTE_REPO_PATH`
- Lokal: `$REPO`

## Ablauf

### 1. xpstopdf sicherstellen

```bash
$SSH_CMD "test -f /tmp/gxps_tools/usr/bin/xpstopdf && echo 'OK' || echo 'FEHLT'"
```

Falls FEHLT:
```bash
$SSH_CMD "cd /tmp && apt-get download libgxps-utils 2>&1 | tail -1 && dpkg -x libgxps-utils*.deb /tmp/gxps_tools"
```

### 2. Unterordner scannen

```bash
$SSH_CMD "find $REMOTE_DOWNLOADS_PATH -maxdepth 1 -mindepth 1 -type d"
```

### 3. Neue XPS-Dateien erkennen

Eine XPS-Datei gilt als **neu**, wenn die entsprechende PDF im Zielordner noch nicht existiert:

```bash
$SSH_CMD "
for f in $REMOTE_DOWNLOADS_PATH/<unterordner>/*.xps; do
  [ -f \"\$f\" ] || continue
  base=\$(basename \"\$f\" .xps)
  ziel=<zielordner>/\${base}.pdf
  [ ! -f \"\$ziel\" ] && echo \"NEU: \$f\"
done
"
```

### 4. Neue Dateien konvertieren

```bash
$SSH_CMD "
mkdir -p $REMOTE_REPO_PATH/<zielordner>
/tmp/gxps_tools/usr/bin/xpstopdf \"<quelldatei>\" \"$REMOTE_REPO_PATH/<zielordner>/<name>.pdf\"
"
```

### 5. Auf Host committen und pushen

```bash
$SSH_CMD "
cd $REMOTE_REPO_PATH
git add <zielordner>/<name>.pdf
git commit -m 'Add PDF: <name> aus VIDA-Druck'
git push
"
```

Dann lokal ziehen:
```bash
git -C "$REPO" pull
```

### 6. Zusammenfassung

- Wie viele neue Dateien pro Unterordner gefunden
- Welche Dateien konvertiert wurden (Name + Zielordner)
- Falls kein Unterordner neue XPS hatte: "Keine neuen Dokumente gefunden."
