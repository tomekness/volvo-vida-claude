-- Dokument direkt per VCC-Nummer abrufen
-- Liefert auch den Baum-Kontext (wo hängt das Dokument im Navigationsbaum)
--
-- Quelle: eigenes Schema; VCC-Nummernformat aus VIDA ServiceRepository
-- Beispiel: :vcc = 'VCC-132040-1' (Drosselklappe überprüfen)

SELECT
    d.id,
    d.vcc_number,
    d.version,
    d.chronicle,
    d.title,
    d.doc_type,
    d.xml_size,
    ti.fg1,
    ti.fg2,
    ti.fg3,
    ti.title AS baum_titel
FROM document d
LEFT JOIN tree_doc_link tdl ON tdl.doc_id = d.id
LEFT JOIN tree_item ti      ON ti.id = tdl.tree_id
WHERE d.vcc_number = :vcc;
