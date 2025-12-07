#!/bin/bash

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

PF_DIR="./.pf"

echo -e "${CYAN}🛑 Parando port-forwards${NC}"

if [ ! -d "$PF_DIR" ]; then
    echo -e "${YELLOW}Nenhum port-forward ativo encontrado.${NC}"
    exit 0
fi

# Ler PIDs e matar processos
for pidfile in $PF_DIR/*.pid; do
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        name=$(basename "$pidfile" .pid)
        
        if kill -0 $pid 2>/dev/null; then
            kill $pid
            echo -e "${GREEN}✅ Port-forward $name parado (PID: $pid)${NC}"
        else
            echo -e "${YELLOW}⚠️  Processo $name já não está rodando${NC}"
        fi
        
        rm "$pidfile"
    fi
done

# Remover logs
rm -f $PF_DIR/*.log
echo -e "${GREEN}🧹 Limpeza concluída.${NC}"
