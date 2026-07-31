# vida_debug — Workflows für Claude

Checklisten für VIDA-Debugging. Vor jedem Task lesen.

---

## 1. Session-Start (immer zuerst)

```
1. vida_debug/TODO.md → erster [ ]-Task
2. vida_debug/memory/vida_debug.md → was wurde schon getestet?
3. vida_debug/logs/session_log.md (letzte Einträge) → letzter Status?
4. VM-Status: scripts/vida_status
```

---

## 2. VM-Interaktion

Variablen aus `scripts/config.sh`:
```bash
source "$(git rev-parse --show-toplevel)/scripts/config.sh"
# $HOST_IP, $SSH_PORT, $SSH_USER, $SSH_KEY, $VM_NAME
```

### Text tippen
```bash
ssh -i "$SSH_KEY" -p "$SSH_PORT" "$SSH_USER@$HOST_IP" \
  "VBoxManage controlvm \"$VM_NAME\" keyboardputstring \"text\""
```

### Sondertasten (Scancodes)
```bash
# Enter:
keyboardputscancode 1c 9c
# Win+R (Run-Dialog):
keyboardputscancode e0 5b 13 93 e0 db
# Alt+Tab:
keyboardputscancode 38 0f 8f b8
# F12:
keyboardputscancode 58 d8
# Alt+F4:
keyboardputscancode 38 3e be b8
```

### URL in IE navigieren
**KEIN Alt+D oder Ctrl+L** — führt zu URL-Konkatenierung!
**Immer über CMD:**
```
Win+R → cmd → Enter
start iexplore "http://localhost/Vida/vehicleProfileTabAction.do"
```

### Screenshot
```bash
"$(git rev-parse --show-toplevel)/scripts/vida_screenshot"
```

---

## 3. IE / ActiveX Debug-Checkliste

```
1. prevhost.exe läuft?     →  tasklist | findstr /i prevhost
2. Document mode?          →  F12 Console: document.documentMode
3. CommToolSettings?       →  F12 Console: typeof CommToolSettings
4. UI.DLL erreichbar?      →  curl http://localhost/Vida/Diagnostics/UI.DLL
5. diagnostic.config.xml?  →  curl http://localhost/Vida/Diagnostics/diagnostic.config.xml
6. JBoss Log?              →  server.log auf Errors prüfen
```

Erwartung bei funktionierendem Setup:
```javascript
// F12 Console:
document.documentMode + " | " + typeof CommToolSettings
// → "8 | object"
```

---

## 4. Registry-Befehle (in VM CMD)

```cmd
:: IE Version
reg query "HKLM\SOFTWARE\Microsoft\Internet Explorer" /v Version

:: FEATURE_BROWSER_EMULATION
reg query "HKCU\Software\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION"
reg query "HKLM\SOFTWARE\Microsoft\Internet Explorer\Main\FeatureControl\FEATURE_BROWSER_EMULATION"

:: Zone 1 ActiveX (Intranet)
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Zones\1"

:: J2534 Registry
reg query "HKLM\SOFTWARE\WOW6432Node\PassThruSupport.04.04" /s

:: .NET Versionen
dir "C:\Windows\Microsoft.NET\Framework\"
```

---

## 5. Session-Ende (immer)

```
1. vida_debug/TODO.md → Task abhaken [x]
2. vida_debug/logs/session_log.md → neuen Eintrag oben
3. vida_debug/memory/vida_debug.md → Erkenntnisse, neuer Zustand
4. git push
```

---

## 6. Bekannte Fallstricke

| Problem | Ursache | Fix |
|---|---|---|
| URL wird konkateniert | Adresszeile via VBoxManage unzuverlässig | CMD → `start iexplore "URL"` |
| guestcontrol schlägt fehl | Windows 7 Session-Restriction | Nur keyboardput* nutzen |
| diagnostic.config.xml leer nach Neustart | JBoss überschreibt WAR-Pfad | Immer BEIDE Pfade schreiben |
| Shared Folder (Z:) nicht erreichbar | Guest Additions Versions-Mismatch | Manuell mounten: `net use Z: \\vboxsvr\vidashare` |
| Deutsches Ubuntu-Locale | Ordnernamen anders | `Schreibtisch` nicht `Desktop` |
