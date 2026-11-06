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

_(Nur ausfüllen wenn abweichend oder relevant)_

| Parameter | Wert | Notiz |
|-----------|------|-------|
| Spannung (30) | V | |
| Motordrehzahl | U/min | |
| Motorlast | % | |
| Kühlmitteltemp. | °C | |
| Einspritzzeit | ms | |
| LTFT | % | |
| Fahrgeschwindigkeit | km/h | |

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
