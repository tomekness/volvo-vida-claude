-- Navigation via Volvo Funktionsgruppen (fg1/fg2)
-- Liefert alle Dokumente einer Funktionsgruppe mit Baum-Kontext
--
-- Quelle: tree_item/tree_doc_link-Schema aus import_to_sqlite.py
-- Vgl. OpenVIDA basedata.py Navigationsstruktur: https://github.com/kForth/OpenVIDA
--
-- fg1-Hauptgruppen: 1=Wartung, 2=Motor, 3=Elektrik/SRS, 4=Getriebe,
--                   5=Bremsen, 6=Fahrwerk, 7=Karosserie, 8=Lack
-- Beispiel: fg1='2', fg2='20' → Motor-Dokumente

SELECT
    ti.fg1,
    ti.fg2,
    ti.fg3,
    ti.level,
    ti.title        AS baum_titel,
    d.vcc_number,
    d.title         AS dok_titel,
    d.doc_type
FROM tree_item ti
JOIN tree_doc_link tdl ON tdl.tree_id = ti.id
JOIN document d        ON d.id = tdl.doc_id
WHERE ti.fg1 = :fg1
  AND (:fg2 IS NULL OR ti.fg2 = :fg2)
ORDER BY ti.fg2, ti.fg3, tdl.sort;
