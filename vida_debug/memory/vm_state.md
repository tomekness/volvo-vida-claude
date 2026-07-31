# Memory: VM-Konfigurationsstand

Aktueller bekannter Zustand der VIDA VM. Nach Änderungen aktualisieren.

---

## System

| Was | Stand |
|---|---|
| VM-Name | siehe `scripts/config.sh` → `$VM_NAME` |
| OS | Windows 7 SP1 64-bit |
| VirtualBox | [Version] |
| Guest Additions | [Version] |
| IE-Version | [ausfüllen nach Task A] |
| .NET-Versionen | [ausfüllen nach Task A] |
| VIDA-Version | 2014D |
| JBoss | 7.0.13.Final |

---

## Netzwerk / Ports (VirtualBox NAT)

| Host-Port | VM-Port | Dienst |
|---|---|---|
| 8080 | 80 | VIDA JBoss Web |
| 14333 | 1433 | SQL Server |
| 3389 | 3389 | RDP |

---

## Registry (bekannter Zustand)

```
[Nach jeder Session hier den aktuellen Stand eintragen]

HKCU\...\FEATURE_BROWSER_EMULATION
  iexplore.exe = REG_DWORD [Wert]

HKLM\...\FEATURE_BROWSER_EMULATION
  prevhost.exe = REG_DWORD 0x8   [original]
```

---

## VIDA-Verzeichnisse

```
C:\VIDA\                    ← VIDA Home
C:\VIDA\jboss.bat           ← JBoss-Start
C:\VIDA\jboss\standalone\deployments\VidaEar.ear\VidaWeb.war\
  Diagnostics\
    diagnostic.config.xml   ← WAR-Pfad (primär)
    UI.DLL                  ← CommToolSettingForm Assembly
C:\VIDA\diagnostic.config.xml   ← persistenter Pfad
```

---

## Bekannte Fallstricke

- Guest Additions Versions-Mismatch → Shared Folder instabil
- guestcontrol nicht nutzbar (Session-Restriction) → nur keyboardput*
- IE-Adresszeile per VBoxManage → URL-Konkatenierung → immer CMD nutzen
