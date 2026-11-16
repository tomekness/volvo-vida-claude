# Diagnose-Scan — [DATUM] — [GRUND]

**Datum:** YYYY-MM-DD  
**Kilometerstand:** ___.___ km  
**Interface:** [J2534 interface name]  
**VIDA Version:** 2014D  
**Datenquelle:** VIDA SQL (DiagSwdlSession)  

**Anlass:** _(Baseline / Nach Reparatur: XYZ / Nach Code-Löschung / Symptom: …)_

---

## Fahrzeugzustand vor dem Scan

| | |
|--|--|
| Zündung | Position II (Motor aus) |
| Batteriespannung | ___ V |
| Außentemperatur | ___ °C |
| Motor-Temperatur | kalt / warm / heiß |
| Symptome | _(keine / Motorkontrollleuchte / …)_ |

**Zuletzt gelöscht:** _(nie / Datum: ___)_  
**Gefahren seit letzter Löschung:** ___ km

---

## Scan-Ergebnis

**Steuergeräte gescannt:** ___  
**Fehlercodes gesamt:** ___

### ECM — Motorsteuerung

| Code | Beschreibung | Status | Neu? |
|------|-------------|--------|------|
| | | | |

### CCM — Klimaanlage

| Code | Beschreibung | Status | Neu? |
|------|-------------|--------|------|
| | | | |

### CEM — Karosserieelektronik

| Code | Beschreibung | Status | Neu? |
|------|-------------|--------|------|
| | | | |

### DDM — Fahrertür

| Code | Beschreibung | Status | Neu? |
|------|-------------|--------|------|
| | | | |

### PDM — Beifahrertür

| Code | Beschreibung | Status | Neu? |
|------|-------------|--------|------|
| | | | |

### Weitere Steuergeräte

| ECU | Code | Beschreibung | Status |
|-----|------|-------------|--------|
| | | | |

---

## Freeze-Frame-Werte

_(Nur ausfüllen wenn abweichend oder relevant — Definitionen: `facts/vida_dtc_definitionen.md`)_

| Parameter | Wert | Notiz |
|-----------|------|-------|
| Echtzeit seit Zurücksetzen | s | T=0 des Fehler-Ereignisses (NICHT Zeit seit Code-Löschung) |
| Zeit seit Anlassen | s | Motorlaufzeit in diesem Zündungszyklus (OBD PID 1F) |
| Spannung (30) | V | |
| Motordrehzahl | U/min | |
| Motorlast | % | |
| Kühlmitteltemp. | °C | |
| Einspritzzeit | ms | |
| LTFT / Lambda | | 1.00=±0%, >1.15 ⚠️ |
| Fahrgeschwindigkeit | km/h | |

### Status Identifier (SI) — falls im Ausdruck vorhanden

_(Definitionen: SI 1–9 → `facts/vida_dtc_definitionen.md`)_

| SI | Name | Wert | Bewertung |
|----|------|------|-----------|
| SI 2 | Prüfung abgeschlossen | Ja/Nein | |
| SI 3 | Drohender Fehler vorhanden | Ja/Nein | |
| SI 6 | Prüfung gehemmt | **Nein** = OK / Ja = ⚠️ | |
| SI 8 | Statuszähler aktuell | 0–255 | 255 = dauerhaft aktiv ⚠️ |

### FaultCounter (Zähler)

| Zähler | FC | Wert | Bedeutung |
|--------|-----|------|-----------|
| Zähler 1 | FC1 | | Fehlerfreie Zyklen seit letztem Auftreten |
| Zähler 3 | FC3 | | Betriebszyklen seit erster Erkennung |
| Zähler 4 | FC4 | | Bestätigte Zyklen mit aktivem Fehler |

---

## Aktionen nach dem Scan

- [ ] Alle Codes gelöscht (VIDA "Alle löschen")
- [ ] Nur bestimmte Codes gelöscht
- [ ] Nichts gelöscht
- [ ] Reparatur durchgeführt: ___________

**Nächster Scan empfohlen nach:** ___ km / ___ Wochen

---

## Bewertung

_(Kurze Einschätzung: was ist neu, was ist verschwunden, was ist kritisch)_

**Dein Kommentar:** _(hier eintragen — z.B. Symptome, was du gefahren bist, Auffälligkeiten)_

---

## Rohdaten (SQL-Export)

<details>
<summary>dtc_export.txt</summary>

```
[Hier Rohdaten aus sqlcmd einfügen]
```

</details>

<details>
<summary>freeze_export.txt</summary>

```
[Hier Rohdaten aus sqlcmd einfügen]
```

</details>
