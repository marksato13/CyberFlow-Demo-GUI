#!/bin/bash
# Arranca en el contenedor la cadena del Sensor1, con los mismos argumentos que
# sus unidades systemd (deploy/laboratorio-2026-11-18/sensor1/systemd). Cada
# proceso se relanza si cae. Registros en /var/log/cyberflow/<proceso>.log
set -u
R=/opt/cyberflow
CAP=/var/lib/ppi-motor-capture
FEED=/var/lib/cyberflow/feed-v2
LOGS=/var/log/cyberflow
EXCLUIR="10.10.0.0/24"            # gestión: pasarela de Docker (tu navegador) y herramientas
IFACE=eth0
mkdir -p "$CAP" "$FEED/d5/control" "$FEED/d5/auditoria" "$LOGS" "$R/logs" /var/log/suricata \
         "$R/artifacts/feed-keys"
# tcpdump suelta privilegios al usuario «tcpdump» (como en Sensor1): el anillo es suyo
chown tcpdump:tcpdump "$CAP"; chmod 2755 "$CAP"

# Clave del feed: se crea en cada contenedor nuevo, nunca se versiona.
if [ ! -f "$R/artifacts/feed-keys/priv.pem" ]; then
  openssl genpkey -algorithm ed25519 -out "$R/artifacts/feed-keys/priv.pem"
  openssl pkey -in "$R/artifacts/feed-keys/priv.pem" -pubout -out "$R/artifacts/feed-keys/pub.pem"
  chmod 600 "$R/artifacts/feed-keys/priv.pem"
fi

vigilar() {   # vigilar <nombre> <comando...>: lo relanza 3 s después de cada caída
  local nombre=$1; shift
  ( while :; do
      echo "$(date -u +%FT%TZ) arranca $nombre" >> "$LOGS/$nombre.log"
      "$@" >> "$LOGS/$nombre.log" 2>&1
      echo "$(date -u +%FT%TZ) $nombre terminó (rc $?), relanzo en 3 s" >> "$LOGS/$nombre.log"
      sleep 3
    done ) &
}

# 1 · Captura: anillo de PCAP rotado cada 5 s (ppi-motor-capture)
vigilar captura tcpdump -i "$IFACE" -n -s 0 -U -B 65536 -w "$CAP/live-%Y%m%d%H%M%S.pcap" -G 5

# 2 · Suricata solo como parser: sin reglas, escribe eve.json (http, dns, tls, flow, stats)
vigilar suricata suricata -i "$IFACE" -k none -S /dev/null -l /var/log/suricata

# 3 · Vía rápida de escaneo (ppi-via-rapida@)
vigilar via-rapida bash -c "set -o pipefail; tcpdump -i $IFACE -n -U --immediate-mode -s 128 -w - tcp 2>/dev/null \
  | python $R/scripts/engine/detector_rapido.py --flujo \
      --salida $FEED/senales-rapidas.jsonl --resumen $FEED/via-rapida-resumen.jsonl"

# 4 · Motor (ppi-motor): modelo if_limpio_2026_10, punto operativo alfa 0,01
vigilar motor python $R/scripts/engine/motor_decision.py \
  --eve-path /var/log/suricata/eve.json \
  --capture-dir "$CAP" \
  --model-path $R/artifacts/preliminar/limpio-2026-10/if_limpio_2026_10_desplegable.joblib \
  --manifest-path $R/artifacts/preliminar/limpio-alfa001-B/manifest-if-limpio-2026-10-alfa001.json \
  --detector-name if_limpio_2026_10 \
  --schema $R/configs/features/multilayer-v2.json \
  --entity-network 10.10.0.0/16 \
  --excluir "$EXCLUIR" \
  --excluir-protocolos 112,240 \
  --log-path $R/logs/motor_decision.log \
  --state-dir $R/logs/_state-e4 \
  --step-seconds 10 --history-seconds 230 --disparo eventos

# 5 · Publicador v2 con lista blanca y «Dejar limpio» (ppi-publicar-feed-v2)
vigilar publicador env PYTHONPATH=$R/scripts/engine python $R/deploy/d5/publicar_feed_v2_d5_lb.py \
  --log $R/logs/motor_decision.log --estado $FEED/estado.json \
  --clave-privada $R/artifacts/feed-keys/priv.pem \
  --salida-feed $FEED/feed.json --salida-firma $FEED/feed.sig \
  --senales $FEED/senales-if.jsonl --senales-rapidas $FEED/senales-rapidas.jsonl \
  --traza $FEED/traza.jsonl --politica if_senal --vigencia-segundos 60 --refresco-segundos 20 \
  --seguir --control-d5 $FEED/d5/control/control.json --d5-origen 10.10.20.30 \
  --d5-auditoria $FEED/d5/auditoria/d5-auditoria.jsonl --lista-blanca $R/configs/lista-blanca.json

# 6 · Poda del anillo (cyberflow-limpieza): fuera los PCAP de más de 15 min
( while :; do find "$CAP" -name 'live-*.pcap' -mmin +15 -delete; sleep 60; done ) &

# 7 · Panel (ppi-dashboard), sin login: solo escucha en 127.0.0.1 de tu PC
echo "CyberFlow demo: panel en http://127.0.0.1:8788  (registros en $LOGS)"
exec python $R/scripts/engine/dashboard.py \
  --log-path $R/logs/motor_decision.log \
  --manifest-path $R/artifacts/preliminar/limpio-2026-10/manifest-if-limpio-2026-10.json \
  --detector-name if_limpio_2026_10 \
  --eve-path /var/log/suricata/eve.json \
  --schema $R/configs/features/multilayer-v2.json \
  --schema-extra $R/configs/features/multilayer-v3.json \
  --descripciones $R/configs/features/descripciones.json \
  --dataset $R/artifacts/dataset/multilayer-v2-normal.csv \
  --escenarios $R/configs/escenarios.json \
  --config-toml $R/configs/cyberflow.local.toml \
  --services ppi-motor.service,ppi-motor-capture.service,suricata.service \
  --calibrado-en-esta-red \
  --sin-autenticacion \
  --capture-dir "$CAP" --entity-network 10.10.0.0/16 --excluir "$EXCLUIR" --excluir-protocolos 112,240 \
  --modo-panel v2 --cadena-v2-dir "$FEED" --modo-respuesta "${MODO_RESPUESTA:-sombra}" \
  --control-d5 $FEED/d5/control/control.json \
  --host 0.0.0.0 --port 8788
