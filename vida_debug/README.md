# vida_debug — VIDA Debugging

Strukturiertes Debugging für VIDA 2014D-Probleme. Jeder Fehler bekommt eigene Tasks, Logs und Memory.

## Ordnerstruktur

```
vida_debug/
  README.md           ← diese Datei
  TODO.md             ← offene Debug-Tasks ([ ] / [x] / [-])
  WORKFLOWS.md        ← Best-Practice-Checklisten für Claude
  logs/
    session_log.md    ← chronologisches Log jeder Debug-Session
  memory/
    vida_debug.md     ← aktueller Problem-State (was getestet, was offen)
    vm_state.md       ← VM-Konfigurationsstand (Registry, Versionen, Ports)
```

## Wie benutzen

```
/vida_debug    → arbeitet nächsten offenen [ ]-Task aus TODO.md ab, dann Stop
/vida_debug    → nächster Task (neue Session = frischer Kontext)
```

**Token-schonend:** Ein Task pro Session. Kein langer Kontext-Aufbau.

## Für Claude: Session-Start

1. `vida_debug/TODO.md` lesen — erster `[ ]`-Task
2. `vida_debug/memory/vida_debug.md` lesen — was wurde schon getestet?
3. Task ausführen, dann `logs/session_log.md` + `memory/` updaten
4. pushen + **stoppen**

## Für Claude: Session-Ende (immer!)

- TODO.md: Task abhaken
- logs/session_log.md: Eintrag oben hinzufügen
- memory/vida_debug.md: Erkenntnisse + neuen Registry-Zustand
- `git push`
