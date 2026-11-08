-- Volltext-Suche über Dokumenttitel + VCC-Nummer
-- FTS5-Index, Ranking nach Relevanz
--
-- Quelle: FTS5-Schema aus volvo-repair-app/extractor/import_to_sqlite.py
-- Verwendung: :term = Suchbegriff (z.B. 'Drosselklappe' oder 'P0507')
--             :limit = max. Ergebnisse (default 30)

SELECT
    d.vcc_number,
    d.title,
    d.doc_type,
    d.xml_size
FROM document_fts
JOIN document d ON d.id = document_fts.id
WHERE document_fts MATCH :term
ORDER BY rank
LIMIT :limit;
