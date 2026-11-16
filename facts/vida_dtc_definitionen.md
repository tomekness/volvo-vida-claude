# VIDA DTC — Definitionen für Freeze Frame, Status Identifier, FaultCounter

**Quelle:** VIDA SQL — `DiagSwdlSession.StatusIdentifier` + `.FaultCounter` (VIDA 2014D)  
**Gilt für:** VIDA 2014D, alle ECUs (ECM, CCM, CEM, PDM, DDM, …)

---

## Status Identifier (SI) — direkt aus der VIDA-DB

Die SI-Werte werden in `DiagSwdlSession.StatusIdentifier` gespeichert.  
`statusidentifierid` = SI-Nummer, `statusidentifiervalue` = 0 oder 1 (bei SI 8/9: 0–255).

| SI-Nr | DB-Name | Wert 0 | Wert 1 | Kurzform |
|-------|---------|--------|--------|----------|
| SI 1 | Prüfung läuft nun | Nein | Ja | Test gerade aktiv |
| SI 2 | Prüfung ist abgeschlossen worden | Nein | Ja | Test lief vollständig durch |
| SI 3 | Drohender Fehler ist nun vorhanden | Nein | Ja | Pending Fault jetzt aktiv |
| SI 4 | Drohender Fehler war vorhanden | Nein | Ja | Pending Fault war in vergangenem Zyklus vorhanden |
| SI 5 | Warnleuchte ist eingeschaltet worden | Nein | Ja | MIL leuchtet |
| SI 6 | Prüfung wird gehemmt | Nein | Ja | Test blockiert durch anderen Fehler |
| SI 8 | Statuszähler - aktueller Wert | 0–255 | | Fehlererkennungszähler (aktueller Zyklus) |
| SI 9 | Statuszähler - Höchstwert | 0–255 | | Fehlererkennungszähler (Maximum im Zyklus) |

**SI 7 fehlt** — in dieser VIDA-Version nicht belegt.

### Interpretationsregeln

**SI 6 = Nein** → Test läuft unblockiert. Ein anderer aktiver Fehler blockiert diesen Diagnosetest **nicht**.  
**SI 6 = Ja** → Test gehemmt. Zuerst den blockierenden Fehler beheben, dann diesen Test erneut auswerten.

**SI 3 "Drohender Fehler"** = OBD-II Pending DTC — Fehler wurde erkannt, aber Bestätigungsschwelle noch nicht erreicht.  
Ist SI 3=Ja und SI 8=255 → Fehler sofort und dauerhaft aktiv (Schwelle sofort überschritten).

**SI 8/9 = 255** = Maximalwert gesättigt. Der ECU erkennt den Fehler in jeder möglichen Betriebssekunde sobald der Monitor aktiv ist.

---

## FaultCounter — Zähler-Definitionen

Tabelle `DiagSwdlSession.FaultCounter`. VIDA zeigt die Zähler im Detail-Ausdruck als "Zähler 1", "Zähler 3" etc.

| DB-Feld `countername` | VIDA-Anzeige | Bedeutung |
|-----------------------|-------------|-----------|
| FC1 | Zähler 1 | Fehlerfreie Betriebszyklen seit letztem Auftreten |
| FC3 | Zähler 3 | Betriebszyklen seit erster Fehlerermittlung |
| FC4 | Zähler 4 | Bestätigte Betriebszyklen mit aktivem Fehler |
| FC5 | (Distanz-Zähler) | km seit erster Fehlerermittlung — 16777215 = max/kein Wert |
| FC6 | (Distanz-Zähler) | km seit letztem Auftreten |
| FC7 | (selten) | — |

### Typische Muster

| Zähler 1 | Zähler 3 | Zähler 4 | Bedeutung |
|----------|----------|----------|-----------|
| 0 | 1 | 1 | Erster Zyklus, sofort aktiv |
| 0 | 2 | 4 | Seit 2 Zyklen bekannt, 4× bestätigt (kurze Starts zählen nicht) |
| 5 | 10 | 3 | 5 fehlerfreie Zyklen seitdem, insgesamt 10 Zyklen |
| 0 | — | — | Letzter Zyklus hatte Fehler — kein fehlerfreier Zyklus dazwischen |

---

## Freeze Frame — kritische Parameterdeutung

### "Echtzeit seit Zurücksetzen"

**FALSCH:** "0 s = sofort nach Code-Löschung"  
**RICHTIG:** T=0 des Fehler-Ereignisses selbst — der Moment der ersten Erkennung in diesem Auftreten

Der Freeze Frame wird beim **ersten Bestätigen** des Fehlers eingefroren. 0 s bedeutet: der Fehler wurde im ersten möglichen Moment erkannt, in dem der Monitor aktiv war — unabhängig davon, wann die Codes zuletzt gelöscht wurden.

### "Zeit seit Anlassen" (OBD PID 0x1F)

Sekunden seit dem letzten Motorstart (aktuelle Zündungsperiode).

Beispiel: "Zeit seit Anlassen: 59 s" bei einem Fehler mit ~60 s Monitor-Freigabebedingung bedeutet:
- Monitor läuft erst ab ~60 s → kurze Starts lösen keinen Fehler aus
- Sobald Monitor aktiv → Fehler sofort erkannt (SI 8=255)

### Monitor-Freigabebedingungen

Viele ECU-Monitore haben Freigabebedingungen (Laufzeit, Temperatur, Last). Wenn "Zeit seit Anlassen" kurz nach dem Warmstart = wenn der Fehler erscheint, deutet das auf eine Laufzeit-abhängige Freigabebedingung hin.

### Weitere Freeze-Frame-Parameter

| Parameter | OBD-PID | Einheit | Typischer Wertebereich |
|-----------|---------|---------|----------------------|
| Echtzeit seit Zurücksetzen | 0x14 | s | 0 = erster Erkennungsmoment |
| Zeit seit Anlassen | 0x1F | s | 0–65535 |
| Zeit seit DTC-Löschung | 0x4E | min | (nicht "Echtzeit seit Zurücksetzen"!) |
| LTFT (Langzeitkraftstoff-Trim) | 0x07 | Faktor | 1.00 = ±0%, 1.27 = +27% ⚠️ |
| STFT (Kurzzeitkraftstoff-Trim) | 0x06 | Faktor | 1.00 = ±0% |
| Impulsweite Sensor | — | % | >100% = Sensor-Totalausfall ⚠️ |

---

## Praxis-Checkliste beim Freeze Frame dokumentieren

1. "Echtzeit seit Zurücksetzen" → T=0 des Fault-Events (NICHT Zeit seit Code-Löschung)
2. "Zeit seit Anlassen" → Motorlaufzeit in Sekunden in DIESEM Zündungszyklus
3. SI 6 prüfen: Nein = unblockiert (normal), Ja = blockiert (warum? → anderen Fehler zuerst)
4. SI 8/9 = 255 → dauerhaft aktiv; = 0–10 → gerade erst erkannt
5. Zähler 1 = 0: letzter Betriebszyklus hatte Fehler; > 0: so viele fehlerfreie Zyklen seitdem
6. Zähler 3 ≈ Zähler 4: Fehler wird immer bestätigt wenn Test läuft
7. LTFT > 1.15 (> +15%) oder < 0.85 (< −15%) → Kraftstoff-Trim erhöht → dokumentieren
