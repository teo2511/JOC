#!/usr/bin/env bash
# Lanza dos procesos de Godot (anfitrión y cliente) conectados en este PC y comprueba
# que el multijugador funciona. Uso: tools/run_net_test.sh [ruta_a_godot]
GODOT="${1:-godot}"
cd "$(dirname "$0")/.."
"$GODOT" --headless res://tests/net_test.tscn -- --role=host > /tmp/net_host.log 2>&1 &
HOST_PID=$!
sleep 1
timeout 60 "$GODOT" --headless res://tests/net_test.tscn -- --role=client > /tmp/net_client.log 2>&1
CLIENT=$?
timeout 30 tail --pid=$HOST_PID -f /dev/null
wait $HOST_PID; HOST=$?
grep -E "OK|FALLO|pruebas|ERROR" /tmp/net_host.log
grep -E "OK|FALLO|pruebas|ERROR" /tmp/net_client.log
echo "anfitrión=$HOST cliente=$CLIENT"
[ $HOST -eq 0 ] && [ $CLIENT -eq 0 ]
