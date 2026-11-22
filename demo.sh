#!/usr/bin/env bash
# CyberFlow · demo en Docker (Linux / macOS / Git Bash)
#
#   ./demo.sh iniciar            construye y levanta el laboratorio
#   ./demo.sh iniciar --manual   igual, pero la Kali NO ataca sola
#   ./demo.sh ataque l4          lanza un escenario: l4 | brute | l7 | l3 | dns | fp | intenso
#   ./demo.sh estado             contenedores y últimas decisiones del motor
#   ./demo.sh registros          registros del sensor (Ctrl+C para salir)
#   ./demo.sh capturas           guarda una captura de cada vista en docs/capturas
#   ./demo.sh parar              apaga y borra los contenedores (no deja nada)
set -euo pipefail
cd "$(dirname "$0")"
PANEL=http://127.0.0.1:8788

case "${1:-ayuda}" in
  iniciar)
    if [ "${2:-}" = "--manual" ]; then export AUTO=0; else export AUTO=1; fi
    docker compose up -d --build
    printf '\nEsperando al panel'
    for _ in $(seq 60); do curl -fs -o /dev/null "$PANEL" && break; sleep 2; printf '.'; done
    printf '\nPanel: %s\n' "$PANEL"
    echo "El motor necesita ~1-2 min de tráfico antes de evaluar ventanas completas."
    [ "$AUTO" = 1 ] && echo "La Kali empieza su ciclo de ataques a los 90 s (escaneo, fuerza bruta, flood, legítimo)."
    ;;
  ataque)
    case "${2:-}" in l4|brute|l7|l3|dns|fp|intenso) ;; *) echo "uso: ./demo.sh ataque l4|brute|l7|l3|dns|fp|intenso" >&2; exit 2 ;; esac
    if [ "$2" = intenso ]; then docker compose exec cliente1 legitimo-intenso; else docker compose exec kali ataque "$2"; fi ;;
  estado)
    docker compose ps
    docker compose exec -T sensor sh -c "tail -n 400 /opt/cyberflow/logs/motor_decision.log | python /opt/cyberflow/herramientas-demo/resumen.py" ;;
  registros) docker compose exec sensor sh -c "tail -F /var/log/cyberflow/*.log" ;;
  capturas)
    docker run --rm --network cyberflow-demo_lab --ip 10.10.0.10 -v "$PWD:/w" -w /w \
      mcr.microsoft.com/playwright/python:v1.55.0-noble \
      sh -c "pip install -q playwright==1.55.0 && python herramientas/capturas.py" ;;
  parar) docker compose down --remove-orphans ;;
  *) sed -n '2,10p' "$0" ;;
esac
