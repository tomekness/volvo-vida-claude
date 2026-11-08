#!/usr/bin/env bash
# Gemeinsame Hilfsfunktionen für alle vida_* Scripts.
# Voraussetzung: config.sh wurde bereits gesourced (AGENT_MODE, SSH_* Variablen).

# run_cmd — Befehl lokal oder per SSH ausführen, je nach AGENT_MODE
run_cmd() {
  if [ "${AGENT_MODE:-ssh}" = "local" ]; then
    bash -c "$1"
  else
    ssh -i "$SSH_KEY" -p "$SSH_PORT" \
        -o StrictHostKeyChecking=no \
        -o BatchMode=yes \
        "$SSH_USER@$SSH_HOST" "$1"
  fi
}

# get_remote_file — Datei vom Host holen (scp oder cp, je nach AGENT_MODE)
get_remote_file() {
  local remote_path="$1"
  local local_path="$2"
  if [ "${AGENT_MODE:-ssh}" = "local" ]; then
    cp "$remote_path" "$local_path"
  else
    scp -i "$SSH_KEY" -P "$SSH_PORT" -q \
        "$SSH_USER@$SSH_HOST:$remote_path" "$local_path"
  fi
}
