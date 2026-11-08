# VIDA SQL Query-Vorlagen

Queries für `vida_docs.db` — SQLite-Datenbank mit VIDA-Reparaturdokumenten (ServiceRepository).

## Schema

```
document        — Reparaturdokumente (id, vcc_number, title, doc_type, xml_content BLOB)
document_fts    — FTS5-Volltext-Index über title + vcc_number
tree_item       — Navigationsbaum (fg1/fg2/fg3 = Volvo Funktionsgruppen, level 1–4)
tree_doc_link   — n:m-Verknüpfung tree_item ↔ document
```

**doc_type-Bedeutung** (aus Daten abgeleitet):
- 2 = Prüfanleitung / Messverfahren
- 4 = Fehlersuche (Fault-tracing)
- 5 = Information / Hintergrund
- 6 = Einbauanleitung
- 7 = Spezialwerkzeug-Doku
- 11 = (intern/ohne Titel)

**fg1-Hauptgruppen** (Volvo Funktionsgruppen-System):
- 0 = Allgemein / Werkzeuge
- 1 = Wartung / Schmierung
- 2 = Motor
- 3 = Elektrisch / SRS
- 4 = Getriebe
- 5 = Bremsen
- 6 = Fahrwerk / Lenkung
- 7 = Karosserie
- 8 = Lackierung / Korrosionsschutz
- 9 = Sonderfahrzeuge

## Ausführen

```bash
# Einzel-Query (lokal):
python3 -c "
import sqlite3
conn = sqlite3.connect(os.path.expanduser('~/vida_docs.db'))
# ... query hier ...
"

# Oder über den vorhandenen Wrapper:
./scripts/vida_docs_query.sh "Drosselklappe"
```

## Quellen

- Datenbankschema: `volvo-repair-app/extractor/import_to_sqlite.py`
- OpenVIDA (kForth): ServiceRepository-Querymuster → https://github.com/kForth/OpenVIDA
- Volvo Funktionsgruppen: VIDA 2014D Navigationsstruktur
