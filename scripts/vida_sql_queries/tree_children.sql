-- Navigationsbaum: Alle Kinder eines Baum-Knotens auflisten
-- Nützlich um einen Bereich zu erkunden bevor Dokumente geladen werden
--
-- Quelle: tree_item-Hierarchie (level 1–4) aus import_to_sqlite.py
-- Inspiration: OpenVIDA basedata.py get_tree_children(): https://github.com/kForth/OpenVIDA
--
-- :fg1, :fg2 setzen — :fg2=NULL für Top-Level einer Hauptgruppe
-- :level = gewünschte Ebene (2=Hauptthemen, 3=Unterthemen, 4=Blätter)

SELECT
    ti.id,
    ti.fg1,
    ti.fg2,
    ti.fg3,
    ti.level,
    ti.title,
    ti.vcc_number,
    COUNT(tdl.doc_id) AS dok_anzahl
FROM tree_item ti
LEFT JOIN tree_doc_link tdl ON tdl.tree_id = ti.id
WHERE ti.fg1 = :fg1
  AND (:fg2 IS NULL OR ti.fg2 = :fg2)
  AND (:level IS NULL OR ti.level = :level)
GROUP BY ti.id
ORDER BY ti.fg2, ti.fg3, ti.title;
