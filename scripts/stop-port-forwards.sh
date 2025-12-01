#!/usr/bin/env bash
set -euo pipefail

erra() { echo -e "\e[31m$*\e[0m"; }
ok()  { echo -e "\e[32m$*\e[0m"; }

DIR="./.pf"
if [[ ! -d "$DIR" ]]; then erra "Nenhum diretório $DIR encontrado."; exit 0; fi

shopt -s nullglob
PIDS=( "$DIR"/*.pid )
if (( ${#PIDS[@]} == 0 )); then erra "Nenhum PID para matar."; exit 0; fi

for f in "${PIDS[@]}"; do
  if [[ -s "$f" ]]; then
    PID=$(cat "$f" || true)
    if [[ -n "${PID:-}" ]] && kill -0 "$PID" 2>/dev/null; then
      kill "$PID" || true
      ok "Finalizado PID $PID ($f)"
    fi
  fi
  rm -f "$f"
done

rm -f "$DIR"/*.log || true
ok "Port-forwards parados e arquivos .pid/.log removidos."
