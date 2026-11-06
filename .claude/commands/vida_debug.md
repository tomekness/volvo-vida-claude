Führe genau EINEN offenen Debug-Task aus `vida_debug/TODO.md` aus. Danach stoppen.

## Startup (minimal lesen)

1. Lese `vida_debug/TODO.md` — finde erste Zeile mit `[ ]` unter "Aktiv"
2. Lese `vida_debug/memory/vida_debug.md` — nur den Abschnitt zum gefundenen Task
3. Prüfe VM-Status: `"$(git rev-parse --show-toplevel)/scripts/vida_status"`

## Task ausführen

Führe den Task vollständig aus. Nutze die Befehle aus `vida_debug/WORKFLOWS.md`.

**VM-Interaktion** (SSH → Host → VBoxManage):
```bash
source "$(git rev-parse --show-toplevel)/scripts/config.sh"
ssh -i "$SSH_KEY" -p "$SSH_PORT" -o BatchMode=yes "$SSH_USER@$SSH_HOST" \
  "VBoxManage controlvm \"$VM_NAME\" keyboardputstring \"BEFEHL\""
ssh -i "$SSH_KEY" -p "$SSH_PORT" -o BatchMode=yes "$SSH_USER@$SSH_HOST" \
  "VBoxManage controlvm \"$VM_NAME\" keyboardputscancode 1c 9c"  # Enter
```

**URL in IE navigieren** — IMMER über CMD (nie Adresszeile):
```
Win+R (e0 5b 13 93 e0 db) → cmd → Enter → start iexplore "URL" → Enter
```

**Screenshot** nach jeder VM-Aktion:
```bash
"$(git rev-parse --show-toplevel)/scripts/vida_screenshot"
```

**Erfolgsindikator für CommToolSettings:**
```cmd
tasklist | findstr /i prevhost
```
→ prevhost.exe läuft = CommToolSettingForm lädt = Fix erfolgreich.

## Nach dem Task

1. Markiere Task in `vida_debug/TODO.md`: `[ ]` → `[x]` + kurze Notiz
2. Schreibe Ergebnis in `vida_debug/logs/session_log.md` (oben, Datum + Ergebnis)
3. Update `vida_debug/memory/vida_debug.md` — Registry-Zustand, was getestet wurde
4. `git add vida_debug/ && git commit -m "vida_debug: Task X erledigt" && git push`

## STOP

Berichte dem User:
- Welcher Task wurde ausgeführt
- Ergebnis in einem Satz
- Welcher Task als nächstes kommt
- "Starte `/vida_debug` für den nächsten Task"

Nicht selbstständig zum nächsten Task übergehen — jeder Task ist eine eigene Session.
