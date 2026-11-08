-- Fehlersuche-Dokumente (doc_type=4) zu einem DTC-Code finden
-- Kombiniert FTS-Suche mit doc_type-Filter
--
-- Quelle: doc_type-Bedeutung aus Datenbankanalyse 2026-11-08
-- Vgl. Tigo2000/Volvo-VIDA SQL/Get-CANValuesUsingEcuId.sql für DTC-Zuordnung
--       in CarCom-DB (andere DB, nicht diese hier)
--
-- Beispiel: :dtc = 'P0507' oder 'ETM' oder 'Drosselklappe'

SELECT
    d.vcc_number,
    d.title,
    d.doc_type,
    ti.fg1,
    ti.fg2,
    ti.title AS baum_titel
FROM document_fts
JOIN document d        ON d.id = document_fts.id
LEFT JOIN tree_doc_link tdl ON tdl.doc_id = d.id
LEFT JOIN tree_item ti      ON ti.id = tdl.tree_id
WHERE document_fts MATCH :dtc
  AND d.doc_type = 4
ORDER BY rank
LIMIT 20;
