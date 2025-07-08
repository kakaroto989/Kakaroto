#!/bin/bash
set -e  # Detener ejecución si algún comando falla

echo "[INFO] Iniciando badvpn-udpgw..."
tmux new-session -d -s a0 'badvpn-udpgw --listen-addr 127.0.0.1:7300 --max-clients 250 --max-connections-for-client 3'

echo "[INFO] Iniciando dropbear..."
tmux new-session -d -s b0 'dropbear -REF -p 40000 -W 65535'

#echo "[INFO] Iniciando stunnel..."
#tmux new-session -d -s c0 'stunnel'

echo "[INFO] Ejecutando proxy nodejs..."
node proxy3.js

echo "[INFO] Script finalizado."
exit 0
