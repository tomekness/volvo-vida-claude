#!/usr/bin/env bash
# Sucht in vida_docs.db — lokal oder via SSH, je nach config.sh
#
# Aufruf: vida_docs_query.sh SUCHBEGRIFF [LIMIT]
# Ausgabe: vcc_number -- title  (eine Zeile pro Treffer)
#
# Konfiguration via config.sh:
#   VIDA_DOCS_LOCAL=0  → SSH zum Host, DB-Pfad auf dem Host
#   VIDA_DOCS_LOCAL=1  → direkte lokale Abfrage
#   VIDA_DOCS_DB_PATH  → Pfad zur vida_docs.db (auf dem jeweiligen Rechner)

set -euo pipefail

REPO=$(git rev-parse --show-toplevel)
source "$REPO/scripts/config.sh"

TERM="${1:?Suchbegriff fehlt — Aufruf: vida_docs_query.sh SUCHBEGRIFF [LIMIT]}"
LIMIT="${2:-30}"

# Python-Script liest DB-Pfad und Suchbegriff aus sys.argv
# damit Sonderzeichen im Suchbegriff sicher übergeben werden
read -r -d '' PYTHON_BODY <<'PYEOF' || true
import sqlite3, os, sys
path = os.path.expanduser(sys.argv[1])
term = sys.argv[2]
limit = int(sys.argv[3])
if not os.path.exists(path):
    print(f"FEHLER: vida_docs.db nicht gefunden: {path}", file=sys.stderr)
    sys.exit(1)
db = sqlite3.connect(path)
rows = db.execute(
    "SELECT vcc_number, title FROM document_fts WHERE document_fts MATCH ? ORDER BY rank LIMIT ?",
    (term, limit)
).fetchall()
for r in rows:
    print(r[0], "--", r[1])
PYEOF

if [ "${VIDA_DOCS_LOCAL:-0}" = "1" ]; then
    python3 -c "$PYTHON_BODY" "$VIDA_DOCS_DB_PATH" "$TERM" "$LIMIT"
else
    echo "$PYTHON_BODY" | \
        ssh -i "$SSH_KEY" -p "$SSH_PORT" -o StrictHostKeyChecking=no "$SSH_USER@$SSH_HOST" \
        "python3 - '$VIDA_DOCS_DB_PATH' '$TERM' '$LIMIT'"
fi
